<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\LeaveRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LeaveRequestController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'type' => 'required|in:cuti,izin,sakit',
            'reason' => 'required|string',
            'attachment' => 'required|image|mimes:jpeg,jpg,png,webp|max:2048',
        ]);

        $attachmentPath = $request->file('attachment')->store('leave_attachments', 'public');

        $leaveRequest = LeaveRequest::create([
            'user_id' => Auth::id(),
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'type' => $request->type,
            'reason' => $request->reason,
            'attachment_path' => $attachmentPath,
            'status' => 'pending',
        ]);

        return ApiResponse::success($leaveRequest, 'Pengajuan cuti/izin berhasil dikirim.');
    }

    public function index()
    {
        $leaveRequests = LeaveRequest::where('user_id', Auth::id())->latest()->get();
        return ApiResponse::success($leaveRequests, 'Daftar pengajuan berhasil diambil.');
    }
}
