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
        $this->getJson('/api/reports')->assertStatus(200);

        // Cannot access attendance
        $this->getJson('/api/attendance/today')->assertStatus(403);

        // Cannot access schedule
        $this->getJson('/api/schedules')->assertStatus(403);
    }
}
