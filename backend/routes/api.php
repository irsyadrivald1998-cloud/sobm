<?php

use App\Http\Controllers\Api\AuthController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Route publik (tidak perlu autentikasi)
Route::post('/login', [AuthController::class, 'login']);

// Route yang memerlukan autentikasi
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
});
