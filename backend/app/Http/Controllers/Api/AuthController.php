<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|string',
            'password' => 'required|string',
        ]);

        $key = 'login-attempts:' . $request->ip();

        if (RateLimiter::tooManyAttempts($key, 5)) {
            throw ValidationException::withMessages([
                'employee_id' => ['Terlalu banyak percobaan. Silakan coba lagi nanti.'],
            ]);
        }

        $user = User::where('employee_id', $request->employee_id)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            RateLimiter::hit($key, 300);
            throw ValidationException::withMessages([
                'employee_id' => ['Kredensial tidak valid.'],
            ]);
        }

        RateLimiter::clear($key);

        return ApiResponse::success([
            'user' => $user,
            'token' => $user->createToken('mobile-app', ['*'], now()->addDays(7))->plainTextToken,
        ], 'Login berhasil.');
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return ApiResponse::success(null, 'Berhasil keluar.');
    }

    public function forgotPassword(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|string',
        ]);

        $user = User::where('employee_id', $request->employee_id)->first();

        if (! $user) {
            return ApiResponse::error('Employee ID tidak ditemukan.', 404);
        }

        // Generate reset token
        $token = \Illuminate\Support\Str::random(60);
        $user->password_reset_token = $token;
        $user->password_reset_expires_at = now()->addHours(1);
        $user->save();

        // In production, send email/SMS with the token
        // For now, return the token for testing
        return ApiResponse::success([
            'reset_token' => $token,
            'expires_at' => $user->password_reset_expires_at,
        ], 'Token reset password telah dibuat. Valid selama 1 jam.');
    }

    public function resetPassword(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|string',
            'token' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::where('employee_id', $request->employee_id)
            ->where('password_reset_token', $request->token)
            ->where('password_reset_expires_at', '>', now())
            ->first();

        if (! $user) {
            return ApiResponse::error('Token tidak valid atau sudah kadaluarsa.', 400);
        }

        $user->password = Hash::make($request->new_password);
        $user->password_reset_token = null;
        $user->password_reset_expires_at = null;
        $user->save();

        // Revoke all tokens for security
        $user->tokens()->delete();

        return ApiResponse::success(null, 'Password berhasil diubah. Silakan login kembali.');
    }
}
