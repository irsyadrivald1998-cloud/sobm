<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreReportRequest;
use App\Http\Responses\ApiResponse;
use App\Models\Report;
use App\Models\Schedule;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    public function store(StoreReportRequest $request)
    {
        $scheduleId = (int) $request->validated('schedule_id');

        try {
            $report = DB::transaction(function () use ($request, $scheduleId) {
                $schedule = Schedule::query()
                    ->with('checkpoint')
                    ->whereKey($scheduleId)
                    ->lockForUpdate()
                    ->firstOrFail();

                if ($schedule->user_id !== $request->user()->id) {
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

                $photoPath = $request->file('photo')->store('reports', 'public');

                try {
                    $report = Report::query()->create([
                        'schedule_id' => $schedule->id,
                        'check_in_time' => now(),
                        'check_in_latitude' => $request->validated('check_in_latitude'),
                        'check_in_longitude' => $request->validated('check_in_longitude'),
                        'photo_path' => $photoPath,
                        'condition_status' => $request->validated('condition_status'),
                        'notes' => $request->validated('notes'),
                    ]);
                } catch (UniqueConstraintViolationException $e) {
                    Storage::disk('public')->delete($photoPath);
                    throw $e;
                }

                $schedule->update(['status' => 'completed']);

                if ($request->validated('condition_status') === 'Ada Kendala') {
                    $report->issue()->create([
                        'issue_description' => $request->validated('issue_description'),
                        'is_resolved' => false,
                    ]);
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
