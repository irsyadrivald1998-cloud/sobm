<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class UserApiAccess
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user() && $request->user()->role === 'user') {
            if ($request->isMethod('GET') && $request->is('api/reports')) {
                return $next($request);
            }
            return ApiResponse::error('Akses ditolak. Role User hanya boleh mengakses feed aktivitas.', 403);
        }

        return $next($request);
    }
}
