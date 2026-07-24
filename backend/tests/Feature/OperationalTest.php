<?php

namespace Tests\Feature;

use App\Models\Area;
use App\Models\Checkpoint;
use App\Models\Issue;
use App\Models\Report;
use App\Models\Schedule;
use App\Models\TaskCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class OperationalTest extends TestCase
{
    use RefreshDatabase;

    // Test Login
    public function test_user_can_login_with_valid_credentials()
    {
        $user = User::factory()->create([
            'employee_id' => 'emp_123',
            'password' => Hash::make('secret_pass'),
            'role' => 'housekeeping',
        ]);

        $response = $this->postJson('/api/login', [
            'employee_id' => 'emp_123',
            'password' => 'secret_pass',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'data' => [
                    'user',
                    'token',
                ],
                'message',
            ]);
    }

    public function test_user_cannot_login_with_invalid_credentials()
    {
        $user = User::factory()->create([
            'employee_id' => 'emp_123',
            'password' => Hash::make('secret_pass'),
            'role' => 'housekeeping',
        ]);

        $response = $this->postJson('/api/login', [
            'employee_id' => 'emp_123',
            'password' => 'wrong_pass',
        ]);

        $response->assertStatus(422);
    }

    // Test Schedule Role Constraint
    public function test_schedule_cannot_be_saved_with_mismatched_role()
    {
        $user = User::factory()->create([
            'role' => 'housekeeping',
        ]);

        $taskCategory = TaskCategory::create([
            'target_role' => 'teknisi',
            'task_name' => 'Perbaiki AC',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => 0.0,
            'longitude' => 0.0,
            'radius_meter' => 100,
        ]);

        $this->expectException(\InvalidArgumentException::class);

        Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '10:00:00',
            'status' => 'pending',
        ]);
    }

    // Test Policy Access (Filament)
    public function test_admin_can_access_filament_and_manipulate_resources()
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $viewer = User::factory()->create(['role' => 'viewer']);
        $worker = User::factory()->create(['role' => 'housekeeping']);

        $this->assertTrue($admin->can('viewAny', User::class));
        $this->assertTrue($admin->can('create', User::class));

        $this->assertTrue($viewer->can('viewAny', User::class));
        $this->assertFalse($viewer->can('create', User::class));

        $this->assertFalse($worker->can('viewAny', User::class));
    }

    // Test Report Submission with Geolocation constraint, duplicate validation
    public function test_report_submission_within_radius()
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'role' => 'housekeeping',
        ]);

        $taskCategory = TaskCategory::create([
            'target_role' => 'housekeeping',
            'task_name' => 'Sapu Lantai',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $schedule = Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '08:00:00',
            'status' => 'pending',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        // Inside radius (exact coordinate)
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports', [
                'schedule_id' => $schedule->id,
                'check_in_latitude' => -0.9432,
                'check_in_longitude' => 100.3539,
                'photo' => UploadedFile::fake()->image('report.jpg'),
                'condition_status' => 'Aman/Bersih',
                'work_description' => 'Membersihkan lantai area kerja.',
                'notes' => 'Semua bersih',
            ]);

        $response->assertStatus(200);
        $this->assertEquals('completed', $schedule->fresh()->status);
        $this->assertDatabaseHas('reports', [
            'schedule_id' => $schedule->id,
            'condition_status' => 'Aman/Bersih',
            'work_description' => 'Membersihkan lantai area kerja.',
        ]);
    }

    public function test_report_submission_outside_radius_fails()
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'role' => 'housekeeping',
        ]);

        $taskCategory = TaskCategory::create([
            'target_role' => 'housekeeping',
            'task_name' => 'Sapu Lantai',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $schedule = Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '08:00:00',
            'status' => 'pending',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        // Outside radius (far coordinate)
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports', [
                'schedule_id' => $schedule->id,
                'check_in_latitude' => -1.9432,
                'check_in_longitude' => 101.3539,
                'photo' => UploadedFile::fake()->image('report.jpg'),
                'condition_status' => 'Aman/Bersih',
                'work_description' => 'Membersihkan lantai area kerja.',
                'notes' => 'Semua bersih',
            ]);

        $response->assertStatus(400);
        $this->assertEquals('pending', $schedule->fresh()->status);
    }

    public function test_report_submission_creates_issue_when_has_problems()
    {
        Storage::fake('public');

        $user = User::factory()->create([
            'role' => 'housekeeping',
        ]);

        $taskCategory = TaskCategory::create([
            'target_role' => 'housekeeping',
            'task_name' => 'Sapu Lantai',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $schedule = Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '08:00:00',
            'status' => 'pending',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports', [
                'schedule_id' => $schedule->id,
                'check_in_latitude' => -0.9432,
                'check_in_longitude' => 100.3539,
                'photo' => UploadedFile::fake()->image('report.jpg'),
                'condition_status' => 'Ada Kendala',
                'work_description' => 'Memeriksa kondisi lantai area kerja.',
                'notes' => 'Ada pipa bocor',
                'issue_description' => 'Pipa bocor di sudut ruangan',
            ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('issues', [
            'issue_description' => 'Pipa bocor di sudut ruangan',
            'is_resolved' => false,
        ]);
    }

    // Test Feed Activities
    public function test_feed_activities_can_be_retrieved()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'data' => [
                    'reports' => [
                        'data',
                        'current_page',
                        'per_page',
                    ],
                ],
                'message',
            ]);
    }

    public function test_feed_activities_can_be_filtered_by_date()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports?date=' . now()->toDateString());

        $response->assertStatus(200);
    }

    public function test_feed_activities_can_be_filtered_by_role()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports?role=housekeeping');

        $response->assertStatus(200);
    }

    public function test_feed_activities_can_be_filtered_by_checkpoint()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports?checkpoint_id=' . $checkpoint->id);

        $response->assertStatus(200);
    }

    public function test_feed_activities_can_be_filtered_by_condition_status()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports?condition_status=Aman/Bersih');

        $response->assertStatus(200);
    }

    public function test_feed_activities_supports_polling_with_since_parameter()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $since = now()->subHour()->toDateTimeString();

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/reports?since=' . $since);

        $response->assertStatus(200);
    }

    // Test Attendance
    public function test_clock_in_requires_photo_and_location()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/attendance/clock-in', [
                'latitude' => -0.9432,
                'longitude' => 100.3539,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(201);
    }

    public function test_clock_out_requires_clock_in_first()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        // Try to clock out without clocking in
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/attendance/clock-out', [
                'latitude' => -0.9432,
                'longitude' => 100.3539,
                'photo' => UploadedFile::fake()->image('selfie.jpg'),
            ]);

        $response->assertStatus(400);
    }

    public function test_get_today_attendance()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->getJson('/api/attendance/today');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'data',
                'message',
            ]);
    }

    // Test Work Description
    public function test_work_description_is_required_in_report()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);

        $taskCategory = TaskCategory::create([
            'target_role' => 'housekeeping',
            'task_name' => 'Sapu Lantai',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $schedule = Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '08:00:00',
            'status' => 'pending',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        // Missing work_description
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports', [
                'schedule_id' => $schedule->id,
                'check_in_latitude' => -0.9432,
                'check_in_longitude' => 100.3539,
                'photo' => UploadedFile::fake()->image('report.jpg'),
                'condition_status' => 'Aman/Bersih',
                'notes' => 'Semua bersih',
            ]);

        $response->assertStatus(422);
    }

    // Test Photo Upload
    public function test_photo_upload_is_required()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);

        $taskCategory = TaskCategory::create([
            'target_role' => 'housekeeping',
            'task_name' => 'Sapu Lantai',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $schedule = Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '08:00:00',
            'status' => 'pending',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        // Missing photo
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports', [
                'schedule_id' => $schedule->id,
                'check_in_latitude' => -0.9432,
                'check_in_longitude' => 100.3539,
                'condition_status' => 'Aman/Bersih',
                'work_description' => 'Membersihkan lantai area kerja.',
            ]);

        $response->assertStatus(422);
    }

    public function test_photo_upload_validates_file_type_and_size()
    {
        Storage::fake('public');

        $user = User::factory()->create(['role' => 'housekeeping']);

        $taskCategory = TaskCategory::create([
            'target_role' => 'housekeeping',
            'task_name' => 'Sapu Lantai',
        ]);

        $area = Area::create(['name' => 'Test Area']);
        $checkpoint = Checkpoint::create([
            'area_id' => $area->id,
            'name' => 'Test Checkpoint',
            'latitude' => -0.9432,
            'longitude' => 100.3539,
            'radius_meter' => 100,
        ]);

        $schedule = Schedule::create([
            'user_id' => $user->id,
            'checkpoint_id' => $checkpoint->id,
            'task_category_id' => $taskCategory->id,
            'shift_date' => now()->toDateString(),
            'scheduled_time' => '08:00:00',
            'status' => 'pending',
        ]);

        $token = $user->createToken('test-token')->plainTextToken;

        // Invalid file type (PDF instead of image)
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/reports', [
                'schedule_id' => $schedule->id,
                'check_in_latitude' => -0.9432,
                'check_in_longitude' => 100.3539,
                'photo' => UploadedFile::fake()->create('document.pdf', 1000),
                'condition_status' => 'Aman/Bersih',
                'work_description' => 'Membersihkan lantai area kerja.',
            ]);

        $response->assertStatus(422);
    }
}
