<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ReportPdfController;

Route::get('/', function () {
    return view('welcome');
});

// PDF Reports - Admin only (accessible from Filament)
Route::middleware(['auth'])->group(function () {
    Route::get('/reports-pdf/users', [ReportPdfController::class, 'users']);
    Route::get('/reports-pdf/attendances', [ReportPdfController::class, 'attendances']);
    Route::get('/reports-pdf/schedules', [ReportPdfController::class, 'schedules']);
    Route::get('/reports-pdf/work-reports', [ReportPdfController::class, 'workReports']);
    Route::get('/reports-pdf/issues', [ReportPdfController::class, 'issues']);
    Route::get('/reports-pdf/leave-requests', [ReportPdfController::class, 'leaveRequests']);
    Route::get('/reports-pdf/dashboard-summary', [ReportPdfController::class, 'dashboardSummary']);
});

// Fallback route to serve uploaded public storage files (e.g. avatars) directly
Route::get('/storage/{path}', function ($path) {
    $filePath = storage_path('app/public/' . $path);
    if (!file_exists($filePath)) {
        abort(404);
    }
    return response()->file($filePath);
})->where('path', '.*');
