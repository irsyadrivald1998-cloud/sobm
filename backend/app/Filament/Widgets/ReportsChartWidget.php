<?php

namespace App\Filament\Widgets;

use App\Models\Report;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\DB;

class ReportsChartWidget extends ChartWidget
{
    protected ?string $heading = 'Grafik Laporan Per Divisi';

    protected function getData(): array
    {
        $data = Report::join('schedules', 'reports.schedule_id', '=', 'schedules.id')
            ->join('users', 'schedules.user_id', '=', 'users.id')
            ->select('users.role', DB::raw('count(*) as total'))
            ->groupBy('users.role')
            ->get();

        $labels = $data->pluck('role')->toArray();
        $totals = $data->pluck('total')->toArray();

        return [
            'datasets' => [
                [
                    'label' => 'Jumlah Laporan',
                    'data' => $totals,
                    'backgroundColor' => ['#f59e0b', '#3b82f6', '#10b981'], // Example colors
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
