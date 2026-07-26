<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\LeaveSubmission;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LeaveSubmissionController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'leave_type' => 'required|in:cuti,izin,sakit',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after_or_equal:start_date',
            'reason'     => 'required|string|max:500',
            'attachment' => 'nullable|file|mimes:jpeg,jpg,png,webp,pdf|max:5120',
        ]);

        // Attachment wajib untuk izin & sakit
        if (in_array($request->leave_type, ['izin', 'sakit']) && !$request->hasFile('attachment')) {
            return ApiResponse::error('Surat izin/sakit wajib dilampirkan.', 422);
        }

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('leave_attachments', 'public');
        }

        $submission = LeaveSubmission::create([
            'user_id'         => Auth::id(),
            'leave_type'      => $request->leave_type,
            'start_date'      => $request->start_date,
            'end_date'        => $request->end_date,
            'reason'          => $request->reason,
            'attachment_path' => $attachmentPath,
        ]);

        return ApiResponse::success($submission, 'Pengajuan berhasil dikirim.');
    }
}
