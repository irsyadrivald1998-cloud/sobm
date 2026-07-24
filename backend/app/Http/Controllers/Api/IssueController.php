<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\Issue;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class IssueController extends Controller
{
    public function updateStatus(Request $request, Issue $issue)
    {
        $request->validate([
            'status' => 'required|in:open,in-progress,resolved',
            'resolution_notes' => 'required_if:status,resolved|string|nullable',
        ]);

        // Additional business logic validation
        if ($request->status === 'resolved' && $issue->status === 'resolved') {
            return ApiResponse::error('Issue sudah dalam status resolved.', 422);
        }

        if ($request->status !== 'resolved' && empty($request->resolution_notes) && $issue->status === 'resolved') {
            // Un-resolving issue, ensure we clear notes in request so they get wiped out
            $request->merge(['resolution_notes' => null]);
        }

        $issue->update([
            'status' => $request->status,
            'resolution_notes' => $request->resolution_notes,
        ]);

        return ApiResponse::success($issue->load('resolvedBy'), 'Status issue berhasil diupdate.');
    }
}
