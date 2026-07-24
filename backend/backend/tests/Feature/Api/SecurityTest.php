<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_sql_injection_on_login_fails()
    {
        $user = User::factory()->create(['employee_id' => 'user1', 'password' => bcrypt('password')]);
        
        $response = $this->postJson('/api/login', [
            'employee_id' => "' OR '1'='1",
            'password' => 'wrong',
        ]);

        $response->assertStatus(422);
    }
}
