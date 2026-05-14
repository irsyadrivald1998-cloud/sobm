<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    public function index(Request $request)
    {
        $schedules = $request->user()->schedules()
            ->with(['checkpoint', 'taskCategory'])
            ->orderBy('shift_date', 'desc')
            ->orderBy('scheduled_time', 'asc')
            ->get();

        return response()->json([
            'schedules' => $schedules,
        ]);
    }
}
