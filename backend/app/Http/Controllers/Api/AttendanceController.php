<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Attendance;
use Carbon\Carbon;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AttendanceController extends Controller
{
    private const OFFICE_LATITUDE = -0.94326885;
    private const OFFICE_LONGITUDE = 100.35396392;
    private const MAX_RADIUS_METERS = 100;

    public function today(Request $request)
    {
        $attendance = Attendance::where('user_id', $request->user()->id)
            ->whereDate('date', Carbon::today())
            ->first();

        if (!$attendance) {
            return ApiResponse::success(null, 'Belum absen hari ini.');
        }

        return ApiResponse::success($attendance, 'Status absen hari ini.');
    }

    public function clockIn(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'photo' => 'required|image|mimes:jpeg,jpg,png,webp|max:2048',
            'notes' => 'nullable|string',
        ]);

        $userId = $request->user()->id;
        $today = Carbon::today()->toDateString();

        // 1. Check if already clocked in
        $exists = Attendance::where('user_id', $userId)
            ->where('date', $today)
            ->exists();

        if ($exists) {
            return ApiResponse::error('Anda sudah melakukan absen masuk hari ini.', 400);
        }

        // 2. Validate Geolocation (Geofence to main office)
        $distance = $this->haversineGreatCircleDistance(
            self::OFFICE_LATITUDE,
            self::OFFICE_LONGITUDE,
            (float) $request->latitude,
            (float) $request->longitude
        );

        if ($distance > self::MAX_RADIUS_METERS) {
            $over = (int) max(0, ceil($distance - self::MAX_RADIUS_METERS));
            return ApiResponse::error("Anda berada {$over} meter di luar jangkauan lokasi kantor untuk absensi.", 400);
        }

        // 3. Determine Lateness Status (Limit: 08:15:00)
        $now = Carbon::now();
        $currentTimeString = $now->toTimeString();
        $limitTime = Carbon::today()->setTime(8, 15, 0);

        $status = $now->greaterThan($limitTime) ? 'Terlambat' : 'Hadir';

        // 4. Store Photo
        $photoPath = $request->file('photo')->store('attendances/clock_in', 'public');

        try {
            $attendance = Attendance::create([
                'user_id' => $userId,
                'date' => $today,
                'clock_in_time' => $currentTimeString,
                'clock_in_latitude' => $request->latitude,
                'clock_in_longitude' => $request->longitude,
                'clock_in_photo_path' => $photoPath,
                'status' => $status,
                'notes' => $request->notes,
            ]);
        } catch (UniqueConstraintViolationException) {
            Storage::disk('public')->delete($photoPath);
            return ApiResponse::error('Anda sudah melakukan absen masuk hari ini.', 400);
        }

        return ApiResponse::success($attendance, 'Absen masuk berhasil dilakukan.', 201);
    }

    public function clockOut(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'photo' => 'required|image|mimes:jpeg,jpg,png,webp|max:2048',
        ]);

        $userId = $request->user()->id;

        // 1. Get today's attendance record using whereDate for reliable date matching
        $attendance = Attendance::where('user_id', $userId)
            ->whereDate('date', Carbon::today())
            ->first();

        if (!$attendance) {
            return ApiResponse::error('Anda belum melakukan absen masuk hari ini.', 400);
        }

        // Use getRawOriginal to check raw null value before cast transforms it
        if ($attendance->getRawOriginal('clock_out_time') !== null) {
            return ApiResponse::error('Anda sudah melakukan absen keluar hari ini.', 400);
        }

        // 2. Validate Geolocation
        $distance = $this->haversineGreatCircleDistance(
            self::OFFICE_LATITUDE,
            self::OFFICE_LONGITUDE,
            (float) $request->latitude,
            (float) $request->longitude
        );

        if ($distance > self::MAX_RADIUS_METERS) {
            $over = (int) max(0, ceil($distance - self::MAX_RADIUS_METERS));
            return ApiResponse::error("Anda berada {$over} meter di luar jangkauan lokasi kantor untuk absensi.", 400);
        }

        // 3. Store Photo & Update
        $photoPath = $request->file('photo')->store('attendances/clock_out', 'public');

        $attendance->update([
            'clock_out_time' => Carbon::now()->toTimeString(),
            'clock_out_latitude' => $request->latitude,
            'clock_out_longitude' => $request->longitude,
            'clock_out_photo_path' => $photoPath,
        ]);

        return ApiResponse::success($attendance, 'Absen keluar berhasil dilakukan.');
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
