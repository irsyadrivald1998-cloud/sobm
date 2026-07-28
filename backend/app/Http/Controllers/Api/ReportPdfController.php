<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use App\Models\User;
use App\Models\Attendance;
use App\Models\Report;
use App\Models\Issue;
use App\Models\LeaveRequest;
use App\Models\Schedule;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportPdfController extends Controller
{
    /**
     * Generate PDF for User Report
     */
    public function users(Request $request)
    {
        $users = User::query()
            ->select('id', 'name', 'employee_id', 'role', 'email', 'created_at')
            ->when($request->role, function ($query, $role) {
                $query->where('role', $role);
            })
            ->orderBy('name')
            ->get();

        $pdf = Pdf::loadView('reports.users', compact('users'))
            ->setPaper('a4', 'landscape');

        return $pdf->download('laporan-data-pengguna-' . now()->format('Y-m-d') . '.pdf');
    }

    /**
     * Generate PDF for Attendance Report
     */
    public function attendances(Request $request)
    {
        $query = Attendance::query()
            ->with('user:id,name,role')
            ->orderBy('date', 'desc');

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereDate('date', '>=', $request->start_date)
                  ->whereDate('date', '<=', $request->end_date);
        }

        if ($request->has('role')) {
            $query->whereHas('user', function ($q) use ($request) {
                $q->where('role', $request->role);
            });
        }

        $attendances = $query->get();

        $pdf = Pdf::loadView('reports.attendances', compact('attendances'))
            ->setPaper('a4', 'landscape');

        return $pdf->download('laporan-absensi-' . now()->format('Y-m-d') . '.pdf');
    }

    /**
     * Generate PDF for Schedule Report
     */
    public function schedules(Request $request)
    {
        $query = Schedule::query()
            ->with([
                'user:id,name,role',
                'checkpoint:id,name',
                'taskCategory:id,task_name'
            ])
            ->orderBy('created_at', 'desc');

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereDate('created_at', '>=', $request->start_date)
                  ->whereDate('created_at', '<=', $request->end_date);
        }

        if ($request->has('role')) {
            $query->whereHas('user', function ($q) use ($request) {
                $q->where('role', $request->role);
            });
        }

        $schedules = $query->get();

        $pdf = Pdf::loadView('reports.schedules', compact('schedules'))
            ->setPaper('a4', 'landscape');

        return $pdf->download('laporan-jadwal-patroli-' . now()->format('Y-m-d') . '.pdf');
    }

    /**
     * Generate PDF for Work Report
     */
    public function workReports(Request $request)
    {
        $query = Report::query()
            ->with([
                'schedule.checkpoint:id,name',
                'schedule.taskCategory:id,task_name',
                'schedule.user:id,name,role',
                'issue'
            ])
            ->orderBy('created_at', 'desc');

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereDate('created_at', '>=', $request->start_date)
                  ->whereDate('created_at', '<=', $request->end_date);
        }

        if ($request->has('role')) {
            $query->whereHas('schedule.user', function ($q) use ($request) {
                $q->where('role', $request->role);
            });
        }

        if ($request->has('condition_status')) {
            $query->where('condition_status', $request->condition_status);
        }

        $reports = $query->get();

        $pdf = Pdf::loadView('reports.work_reports', compact('reports'))
            ->setPaper('a4', 'landscape');

        return $pdf->download('laporan-pekerjaan-' . now()->format('Y-m-d') . '.pdf');
    }

    /**
     * Generate PDF for Issue Report
     */
    public function issues(Request $request)
    {
        $query = Issue::query()
            ->with([
                'report.schedule.user:id,name,role',
                'report.schedule.checkpoint:id,name'
            ])
            ->orderBy('created_at', 'desc');

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereDate('created_at', '>=', $request->start_date)
                  ->whereDate('created_at', '<=', $request->end_date);
        }

        if ($request->has('is_resolved')) {
            $query->where('is_resolved', $request->boolean('is_resolved'));
        }

        $issues = $query->get();

        $pdf = Pdf::loadView('reports.issues', compact('issues'))
            ->setPaper('a4', 'landscape');

        return $pdf->download('laporan-kendala-' . now()->format('Y-m-d') . '.pdf');
    }

    /**
     * Generate PDF for Leave Request Report
     */
    public function leaveRequests(Request $request)
    {
        $query = LeaveRequest::query()
            ->with('user:id,name,role')
            ->orderBy('created_at', 'desc');

        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereDate('start_date', '>=', $request->start_date)
                  ->whereDate('start_date', '<=', $request->end_date);
        }

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }

        $leaveRequests = $query->get();

        $pdf = Pdf::loadView('reports.leave_requests', compact('leaveRequests'))
            ->setPaper('a4', 'landscape');

        return $pdf->download('laporan-cuti-izin-' . now()->format('Y-m-d') . '.pdf');
    }

    /**
     * Generate PDF for Dashboard Summary Report
     */
    public function dashboardSummary(Request $request)
    {
        $startDate = $request->start_date ?? now()->startOfMonth()->toDateString();
        $endDate = $request->end_date ?? now()->endOfMonth()->toDateString();

        // Statistics
        $totalUsers = User::count();
        $totalAttendances = Attendance::whereBetween('date', [$startDate, $endDate])->count();
        $totalReports = Report::whereBetween('created_at', [$startDate, $endDate])->count();
        $totalIssues = Issue::whereBetween('created_at', [$startDate, $endDate])->count();
        $totalLeaveRequests = LeaveRequest::whereBetween('start_date', [$startDate, $endDate])->count();

        // Attendance by status
        $attendanceByStatus = Attendance::whereBetween('date', [$startDate, $endDate])
            ->select('status', DB::raw('count(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status');

        // Reports by condition status
        $reportsByCondition = Report::whereBetween('created_at', [$startDate, $endDate])
            ->select('condition_status', DB::raw('count(*) as count'))
            ->groupBy('condition_status')
            ->pluck('count', 'condition_status');

        // Issues by resolution status
        $issuesByStatus = Issue::whereBetween('created_at', [$startDate, $endDate])
            ->select('is_resolved', DB::raw('count(*) as count'))
            ->groupBy('is_resolved')
            ->pluck('count', 'is_resolved');

        $data = [
            'period' => [
                'start_date' => $startDate,
                'end_date' => $endDate,
            ],
            'statistics' => [
                'total_users' => $totalUsers,
                'total_attendances' => $totalAttendances,
                'total_reports' => $totalReports,
                'total_issues' => $totalIssues,
                'total_leave_requests' => $totalLeaveRequests,
            ],
            'attendance_by_status' => $attendanceByStatus,
            'reports_by_condition' => $reportsByCondition,
            'issues_by_status' => $issuesByStatus,
        ];

        $pdf = Pdf::loadView('reports.dashboard_summary', $data)
            ->setPaper('a4', 'portrait');

        return $pdf->download('laporan-dashboard-' . now()->format('Y-m-d') . '.pdf');
    }
}
