<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreReportRequest;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use App\Models\Report;
use App\Models\Schedule;
use App\Notifications\NewIssueNotification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Notification;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $query = Report::query()
            ->with([
                'schedule.checkpoint',
                'schedule.taskCategory',
                'schedule.user:id,name,role',
                'issue',
            ])
            ->latest('created_at');

        // Filter role
        if ($request->has('role')) {
            $query->whereHas('schedule.user', function ($q) use ($request) {
                $q->where('role', $request->role);
            });
        }

        // Filter date
        if ($request->has('date')) {
            $query->whereDate('created_at', $request->date);
        }

        // Filter checkpoint
        if ($request->has('checkpoint_id')) {
            $query->whereHas('schedule.checkpoint', function ($q) use ($request) {
                $q->where('id', $request->checkpoint_id);
            });
        }

        // Filter condition status
        if ($request->has('condition_status')) {
            $query->where('condition_status', $request->condition_status);
        }

        // Filter for polling - only get reports after a certain timestamp
        if ($request->has('since')) {
            $query->where('created_at', '>', $request->since);
        }

        $reports = $query->paginate(20);

        return ApiResponse::success([
            'reports' => $reports,
        ], 'Aktivitas laporan berhasil diambil.');
    }

    public function store(StoreReportRequest $request)
    {
        $user = $request->user();
        $scheduleId = $request->validated('schedule_id') ? (int) $request->validated('schedule_id') : null;
        $isOsbOrResepsionis = in_array($user->role, ['osb', 'resepsionis']);

        try {
            $report = DB::transaction(function () use ($request, $scheduleId, $user, $isOsbOrResepsionis) {
                $data = [
                    'check_in_time' => now(),
                    'check_in_latitude' => $request->validated('check_in_latitude'),
                    'check_in_longitude' => $request->validated('check_in_longitude'),
                    'photo_path' => $request->file('photo')->store('reports', 'public'),
                    'condition_status' => $request->validated('condition_status'),
                    'work_description' => $request->validated('work_description'),
                    'notes' => $request->validated('notes'),
                ];

                $schedule = null;
                if ($scheduleId) {
                    $schedule = Schedule::query()
                        ->with('checkpoint')
                        ->whereKey($scheduleId)
                        ->lockForUpdate()
                        ->firstOrFail();

                    // Skip validation for OSB & Resepsionis roles
                    if (!$isOsbOrResepsionis) {
                        if ($schedule->user_id !== $user->id) {
                            abort(403, 'Anda tidak berhak mengirim laporan untuk jadwal ini.');
                        }

                        if ($schedule->status === 'completed' || $schedule->report()->exists()) {
                            abort(400, 'Laporan untuk jadwal ini sudah dikirim.');
                        }

                        if ($schedule->shift_date->toDateString() !== now()->toDateString()) {
                            abort(400, 'Laporan hanya bisa disubmit pada hari jadwal yang bersangkutan. Jadwal: '.$schedule->shift_date->toDateString());
                        }

                        $distance = $this->haversineGreatCircleDistance(
                            (float) $schedule->checkpoint->latitude,
                            (float) $schedule->checkpoint->longitude,
                            (float) $request->validated('check_in_latitude'),
                            (float) $request->validated('check_in_longitude')
                        );

                        $radius = (float) $schedule->checkpoint->radius_meter;

                        if ($distance > $radius) {
                            $over = (int) max(0, ceil($distance - $radius));
                            abort(400, "Anda berada {$over} meter di luar jangkauan lokasi tugas ({$schedule->checkpoint->name}).");
                        }
                    }

                    $data['schedule_id'] = $schedule->id;
                }

                $report = Report::query()->create($data);

                if ($schedule) {
                    $schedule->update(['status' => 'completed']);
                }

                if ($request->validated('condition_status') === 'Ada Kendala') {
                    $issue = $report->issue()->create([
                        'issue_description' => $request->validated('issue_description'),
                        'is_resolved' => false,
                    ]);

                    $admins = User::where('role', 'admin')->get();
                    Notification::send($admins, new NewIssueNotification($issue));
                }

                return $report->load('issue');
            });
        } catch (UniqueConstraintViolationException) {
            return ApiResponse::error('Laporan untuk jadwal ini sudah dikirim.', 409);
        }

        return ApiResponse::success($report, 'Laporan berhasil dikirim.');
    }

    private function haversineGreatCircleDistance(
        float $latitudeFrom,
        float $longitudeFrom,
        float $latitudeTo,
        float $longitudeTo
    ): float {
        $earthRadius = 6371000;

        $latFrom = deg2rad($latitudeFrom);
        $lonFrom = deg2rad($longitudeFrom);
        $latTo = deg2rad($latitudeTo);
        $lonTo = deg2rad($longitudeTo);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $angle = 2 * asin(sqrt(pow(sin($latDelta / 2), 2) +
            cos($latFrom) * cos($latTo) * pow(sin($lonDelta / 2), 2)));

        return $angle * $earthRadius;
    }
}
