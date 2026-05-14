<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class WorkerApiAccess
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $allowedRoles = ['housekeeping', 'teknisi', 'security'];

        if (! $request->user() || ! in_array($request->user()->role, $allowedRoles)) {
            return response()->json(['message' => 'Unauthorized. Only workers can access this API.'], 403);
        }

        return $next($request);
    }
}
