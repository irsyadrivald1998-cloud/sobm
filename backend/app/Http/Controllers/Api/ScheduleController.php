<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\Request;

class ScheduleController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'month' => 'nullable|integer|min:1|max:12',
            'year'  => 'nullable|integer|min:2020|max:2100',
        ]);

        $now = Carbon::now('Asia/Jakarta');
        $month = $request->get('month', $now->month);
        $year  = $request->get('year',  $now->year);

        $schedules = $request->user()->schedules()
            ->with(['checkpoint', 'taskCategory'])
            ->whereMonth('shift_date', $month)
            ->whereYear('shift_date', $year)
            ->orderBy('shift_date', 'asc')
            ->orderBy('scheduled_time', 'asc')
            ->get();

        return ApiResponse::success([
            'month' => (int) $month,
            'year'  => (int) $year,
            'schedules' => $schedules,
        ], 'OK');
    }
}
