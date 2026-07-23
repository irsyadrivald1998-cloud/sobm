<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\LeaveSubmission;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LeaveSubmissionController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'date' => 'required|date',
            'type' => 'required|in:cuti,izin,sakit',
            'attachment' => 'required|image|mimes:jpeg,jpg,png,webp|max:2048',
        ]);

        $attachmentPath = $request->file('attachment')->store('leave_attachments', 'public');

        $submission = LeaveSubmission::create([
            'user_id' => Auth::id(),
            'date' => $request->date,
            'type' => $request->type,
            'attachment_path' => $attachmentPath,
        ]);

        return ApiResponse::success($submission, 'Surat berhasil diunggah.');
    }
}
