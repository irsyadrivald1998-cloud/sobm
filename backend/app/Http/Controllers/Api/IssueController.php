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

        $issue->update([
            'status' => $request->status,
            'resolution_notes' => $request->resolution_notes,
            'is_resolved' => $request->status === 'resolved',
            'resolved_at' => $request->status === 'resolved' ? now() : null,
            'resolved_by' => $request->status === 'resolved' ? Auth::id() : null,
        ]);

        return ApiResponse::success($issue->load('resolvedBy'), 'Status issue berhasil diupdate.');
    }
}
