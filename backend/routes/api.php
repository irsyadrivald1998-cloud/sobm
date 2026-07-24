<?php

use App\Http\Controllers\Api\IssueController;
use App\Http\Controllers\Api\LeaveSubmissionController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ScheduleController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', function (Request $request) {
        return ApiResponse::success($request->user(), 'OK');
    });

    // Worker routes
    Route::middleware(['can_access_worker_api', 'report_rate_limit'])->group(function () {
        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::get('/reports', [ReportController::class, 'index']);
        Route::post('/reports', [ReportController::class, 'store']);

        // Attendance
        Route::get('/attendance/today', [AttendanceController::class, 'today']);
        Route::post('/attendance/clock-in', [AttendanceController::class, 'clockIn']);
        Route::post('/attendance/clock-out', [AttendanceController::class, 'clockOut']);
        Route::patch('/issues/{issue}/status', [IssueController::class, 'updateStatus']);
        Route::post('/leave-submissions', [LeaveSubmissionController::class, 'store']);
    });

    // User routes
    Route::middleware('can_access_user_api')->group(function () {
        Route::get('/reports', [ReportController::class, 'index']);
    });
});
