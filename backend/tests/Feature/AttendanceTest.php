<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AttendanceTest extends TestCase
{
    use RefreshDatabase;

    private const OFFICE_LATITUDE = -0.94326885;
    private const OFFICE_LONGITUDE = 100.35396392;

    public function test_get_today_attendance_initially_returns_null()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/v1/attendance/today');

        $response->assertStatus(200)
            ->assertJson([
                'status' => true,
                'data' => null,
            ]);
    }

    public function test_clock_in_within_radius_before_8_15_sets_hadir_status()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        // Mock time to 08:00 AM
        Carbon::setTestNow(Carbon::today()->setTime(8, 0, 0));

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-in', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
                'notes' => 'Tepat waktu',
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'status' => true,
                'data' => [
                    'status' => 'Hadir',
                ],
            ]);

        $this->assertDatabaseHas('attendances', [
            'user_id' => $user->id,
            'status' => 'Hadir',
        ]);

        Carbon::setTestNow(); // Reset mock time
    }

    public function test_clock_in_within_radius_after_8_15_sets_terlambat_status()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        // Mock time to 08:20 AM
        Carbon::setTestNow(Carbon::today()->setTime(8, 20, 0));

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-in', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(201)
            ->assertJson([
                'status' => true,
                'data' => [
                    'status' => 'Terlambat',
                ],
            ]);

        $this->assertDatabaseHas('attendances', [
            'user_id' => $user->id,
            'status' => 'Terlambat',
        ]);

        Carbon::setTestNow(); // Reset mock time
    }

    public function test_clock_in_outside_radius_fails()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        // Office is at -0.94326885, 100.35396392. Let's send a coordinate far away.
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-in', [
                'latitude' => -1.94326885,
                'longitude' => 101.35396392,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(400)
            ->assertJson([
                'status' => false,
            ]);

        $this->assertDatabaseCount('attendances', 0);
    }

    public function test_duplicate_clock_in_fails()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        // Mock time to 08:00 AM
        Carbon::setTestNow(Carbon::today()->setTime(8, 0, 0));

        // First clock in
        $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-in', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        // Second clock in
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-in', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(400);
        $this->assertDatabaseCount('attendances', 1);

        Carbon::setTestNow();
    }

    public function test_clock_out_without_clock_in_fails()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-out', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(400);
    }

    public function test_clock_out_successfully()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        // 1. Clock in
        Carbon::setTestNow(Carbon::today()->setTime(8, 0, 0));
        $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-in', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie1.jpg'),
            ]);

        // 2. Clock out
        Carbon::setTestNow(Carbon::today()->setTime(17, 0, 0));
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/v1/attendance/clock-out', [
                'latitude' => self::OFFICE_LATITUDE,
                'longitude' => self::OFFICE_LONGITUDE,
                'photo' => UploadedFile::fake()->image('selfie2.jpg'),
            ]);

        $response->assertStatus(200);

        $attendance = Attendance::where('user_id', $user->id)->first();
        $this->assertNotNull($attendance->clock_out_time);
        $this->assertNotNull($attendance->clock_out_photo_path);

        Carbon::setTestNow();
    }
}
