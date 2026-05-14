<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\Schedule;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'schedule_id' => 'required|exists:schedules,id',
            'check_in_latitude' => 'required|numeric',
            'check_in_longitude' => 'required|numeric',
            'photo' => 'required|image|mimes:jpeg,png,jpg|max:5120',
            'condition_status' => 'required|in:Aman/Bersih,Ada Kendala',
            'notes' => 'nullable|string',
            'issue_description' => 'required_if:condition_status,Ada Kendala|string',
        ]);

        $schedule = Schedule::with('checkpoint')->findOrFail($request->schedule_id);

        // Ensure user owns schedule
        if ($schedule->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        if ($schedule->status === 'completed') {
            return response()->json(['message' => 'Schedule is already completed'], 400);
        }

        // Validate if schedule date is today
        if ($schedule->shift_date->toDateString() !== now()->toDateString()) {
            return response()->json([
                'message' => 'Laporan hanya bisa disubmit pada hari jadwal yang bersangkutan. Jadwal: ' . $schedule->shift_date->toDateString()
            ], 400);
        }

        // Geofencing Check (Haversine formula)
        $distance = $this->haversineGreatCircleDistance(
            (float) $schedule->checkpoint->latitude,
            (float) $schedule->checkpoint->longitude,
            (float) $request->check_in_latitude,
            (float) $request->check_in_longitude
        );

        if ($distance > $schedule->checkpoint->radius_meter) {
            return response()->json([
                'message' => 'Luar area checkpoint. Jarak Anda: ' . round($distance) . ' meter. Radius diizinkan: ' . $schedule->checkpoint->radius_meter . ' meter.',
            ], 400);
        }

        // Upload photo
        $photoPath = $request->file('photo')->store('reports', 'public');

        // Create Report
        $report = Report::create([
            'schedule_id' => $schedule->id,
            'check_in_time' => now(),
            'check_in_latitude' => $request->check_in_latitude,
            'check_in_longitude' => $request->check_in_longitude,
            'photo_path' => $photoPath,
            'condition_status' => $request->condition_status,
            'notes' => $request->notes,
        ]);

        // Update schedule status
        $schedule->update(['status' => 'completed']);

        // Create Issue if 'Ada Kendala'
        if ($request->condition_status === 'Ada Kendala') {
            $report->issue()->create([
                'issue_description' => $request->issue_description,
                'is_resolved' => false,
            ]);
        }

        return response()->json([
            'message' => 'Report submitted successfully',
            'report' => $report->load('issue'),
        ]);
    }

    private function haversineGreatCircleDistance($latitudeFrom, $longitudeFrom, $latitudeTo, $longitudeTo)
    {
        $earthRadius = 6371000; // in meters

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
