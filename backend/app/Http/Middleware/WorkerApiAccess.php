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
        $allowedRoles = ['housekeeping', 'teknisi', 'security'];

        if (! $request->user() || ! in_array($request->user()->role, $allowedRoles)) {
            return ApiResponse::error('Hanya akun pekerja (housekeeping, teknisi, security) yang dapat mengakses endpoint ini.', 403);
        }

        return $next($request);
    }
}
