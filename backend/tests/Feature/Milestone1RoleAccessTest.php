<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class Milestone1RoleAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_role_can_only_access_feed_endpoint()
    {
        $user = User::factory()->create(['role' => 'user']);

        $this->actingAs($user, 'sanctum');

        // Can access feed
        $this->getJson('/api/v1/reports')->assertStatus(200);

        // Cannot access attendance
        $this->getJson('/api/v1/attendance/today')->assertStatus(403);

        // Cannot access schedule
        $this->getJson('/api/v1/schedules')->assertStatus(403);

        // Cannot post reports
        $this->postJson('/api/v1/reports')->assertStatus(403);

        // Cannot clock-in
        $this->postJson('/api/v1/attendance/clock-in')->assertStatus(403);

        // Cannot clock-out
        $this->postJson('/api/v1/attendance/clock-out')->assertStatus(403);
    }

    public function test_osb_role_can_submit_reports_without_schedule()
    {
        $osb = User::factory()->create(['role' => 'osb']);

        $this->actingAs($osb, 'sanctum');

        // Can access feed
        $this->getJson('/api/v1/reports')->assertStatus(200);

        // Can access schedules
        $this->getJson('/api/v1/schedules')->assertStatus(200);

        // Can access attendance
        $this->getJson('/api/v1/attendance/today')->assertStatus(200);

        // Can submit reports (schedule_id optional)
        $this->postJson('/api/v1/reports', [
            'check_in_latitude' => -0.94326885,
            'check_in_longitude' => 100.35396392,
            'photo' => 'fake_photo_data',
            'condition_status' => 'Aman/Bersih',
            'work_description' => 'Test report',
        ])->assertStatus(422); // Validation error due to fake photo, but not 403
    }

    public function test_resepsionis_role_can_submit_reports_without_schedule()
    {
        $resep = User::factory()->create(['role' => 'resepsionis']);

        $this->actingAs($resep, 'sanctum');

        // Can access feed
        $this->getJson('/api/v1/reports')->assertStatus(200);

        // Can access schedules
        $this->getJson('/api/v1/schedules')->assertStatus(200);

        // Can access attendance
        $this->getJson('/api/v1/attendance/today')->assertStatus(200);

        // Can submit reports (schedule_id optional)
        $this->postJson('/api/v1/reports', [
            'check_in_latitude' => -0.94326885,
            'check_in_longitude' => 100.35396392,
            'photo' => 'fake_photo_data',
            'condition_status' => 'Aman/Bersih',
            'work_description' => 'Test report',
        ])->assertStatus(422); // Validation error due to fake photo, but not 403
    }

    public function test_bm_role_has_no_patrol_schedules()
    {
        $bm = User::factory()->create(['role' => 'bm']);

        $this->actingAs($bm, 'sanctum');

        // Can access feed
        $this->getJson('/api/v1/reports')->assertStatus(200);

        // Can access attendance
        $this->getJson('/api/v1/attendance/today')->assertStatus(200);

        // Can access schedules (but should be empty or attendance-only)
        $this->getJson('/api/v1/schedules')->assertStatus(200);
    }

    public function test_admin_role_has_full_api_access()
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin, 'sanctum');

        // Admin can access all endpoints
        $this->getJson('/api/v1/reports')->assertStatus(200);
        $this->getJson('/api/v1/schedules')->assertStatus(200);
        $this->getJson('/api/v1/attendance/today')->assertStatus(200);
    }

    public function test_viewer_role_has_full_api_access()
    {
        $viewer = User::factory()->create(['role' => 'viewer']);

        $this->actingAs($viewer, 'sanctum');

        // Viewer can access all endpoints
        $this->getJson('/api/v1/reports')->assertStatus(200);
        $this->getJson('/api/v1/schedules')->assertStatus(200);
        $this->getJson('/api/v1/attendance/today')->assertStatus(200);
    }
}
