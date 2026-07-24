<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class WorkerApiAccess
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $allowedRoles = ['admin', 'viewer', 'housekeeping', 'teknisi', 'security', 'osb', 'resepsionis', 'bm'];
        $user = $request->user();

        if (! $user || ! in_array($user->role, $allowedRoles, true)) {
            return ApiResponse::error('Akses ditolak.', 403);
        }

        return $next($request);
    }
}
