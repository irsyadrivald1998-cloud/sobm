<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class InputValidationTest extends TestCase
{
    use RefreshDatabase;

    public function test_empty_string_submission_fails()
    {
        $user = User::factory()->create(['role' => 'housekeeping']);
        $this->actingAs($user, 'sanctum');

        $response = $this->postJson('/api/reports', [
            'check_in_latitude' => '',
            'check_in_longitude' => '',
            'photo' => UploadedFile::fake()->image('test.jpg'),
            'condition_status' => 'Aman/Bersih',
            'work_description' => '',
        ]);

        $response->assertStatus(422);
    }
}
