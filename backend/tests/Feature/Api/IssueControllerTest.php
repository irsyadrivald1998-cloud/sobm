<?php

namespace Tests\Feature\Api;

use App\Models\Issue;
use App\Models\User;
use App\Models\Report;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class IssueControllerTest extends TestCase
{
    use RefreshDatabase;

    private function createReport()
    {
        return Report::factory()->create();
    }

    public function test_can_update_issue_status()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $report = $this->createReport();
        $issue = Issue::create([
            'report_id' => $report->id,
            'status' => 'open',
            'issue_description' => 'desc',
        ]);

        $response = $this->actingAs($user, 'sanctum')->patchJson("/api/issues/{$issue->id}/status", [
            'status' => 'in-progress'
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('issues', [
            'id' => $issue->id,
            'status' => 'in-progress'
        ]);
    }

    public function test_requires_resolution_notes_when_resolved()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $report = $this->createReport();
        $issue = Issue::create([
            'report_id' => $report->id,
            'status' => 'in-progress',
            'issue_description' => 'desc',
        ]);

        $response = $this->actingAs($user, 'sanctum')->patchJson("/api/issues/{$issue->id}/status", [
            'status' => 'resolved'
        ]);

        $response->assertStatus(422);
    }

    public function test_can_resolve_issue_with_notes()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $report = $this->createReport();
        $issue = Issue::create([
            'report_id' => $report->id,
            'status' => 'in-progress',
            'issue_description' => 'desc',
        ]);

        $response = $this->actingAs($user, 'sanctum')->patchJson("/api/issues/{$issue->id}/status", [
            'status' => 'resolved',
            'resolution_notes' => 'Fixed the problem.'
        ]);

        $response->assertStatus(200);
        $this->assertDatabaseHas('issues', [
            'id' => $issue->id,
            'status' => 'resolved',
            'resolution_notes' => 'Fixed the problem.'
        ]);
    }

    public function test_cannot_resolve_already_resolved_issue()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $report = $this->createReport();
        $issue = Issue::create([
            'report_id' => $report->id,
            'status' => 'resolved',
            'issue_description' => 'desc',
        ]);

        $response = $this->actingAs($user, 'sanctum')->patchJson("/api/issues/{$issue->id}/status", [
            'status' => 'resolved',
            'resolution_notes' => 'Another fix.'
        ]);

        $response->assertStatus(422);
    }
}