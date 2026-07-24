<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

class LoginRateLimiting
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $employeeId = $request->input('employee_id');
        $key = 'login-attempt:' . $employeeId . ':' . $request->ip();

        // Check if account is locked
        if (RateLimiter::tooManyAttempts($key, 5)) {
            $seconds = RateLimiter::availableIn($key);
            return ApiResponse::error("Akun dikunci sementara karena terlalu banyak percobaan login gagal. Silakan coba lagi dalam {$seconds} detik.", 429);
        }

        $response = $next($request);

        // If login failed, increment rate limiter
        if ($response->status() === 422) {
            RateLimiter::hit($key, 300); // 5 minutes decay
        }

        // If login successful, clear rate limiter
        if ($response->status() === 200) {
            RateLimiter::clear($key);
        }

        return $response;
    }
}
