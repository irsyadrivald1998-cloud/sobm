<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ReportRateLimiting
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $key = 'report-submission:' . $request->ip();

        if (\Illuminate\Support\Facades\RateLimiter::tooManyAttempts($key, 3)) {
            $seconds = \Illuminate\Support\Facades\RateLimiter::availableIn($key);
            return \App\Http\Responses\ApiResponse::error("Terlalu banyak laporan. Silakan coba lagi dalam $seconds detik.", 429);
        }

        \Illuminate\Support\Facades\RateLimiter::hit($key, 60);

        return $next($request);
    }
}
