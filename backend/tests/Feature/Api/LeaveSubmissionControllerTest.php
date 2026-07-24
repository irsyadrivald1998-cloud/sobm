<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class LeaveSubmissionControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_submit_leave_request()
    {
        Storage::fake('public');
        $user = User::factory()->create(['role' => 'housekeeping']);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/leave-submissions', [
            'date' => now()->toDateString(),
            'type' => 'cuti',
            'attachment' => UploadedFile::fake()->image('cuti.jpg'),
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('leave_submissions', [
            'user_id' => $user->id,
            'type' => 'cuti',
        ]);

        $path = $response->json('data.attachment_path');
        Storage::disk('public')->assertExists($path);
    }

    public function test_requires_required_fields()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/leave-submissions', []);

        $response->assertStatus(422);
    }
}