<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\ScheduleController;
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
    Route::middleware('can_access_worker_api')->group(function () {
        Route::get('/schedules', [ScheduleController::class, 'index']);
        Route::post('/reports', [ReportController::class, 'store']);
    });
});
