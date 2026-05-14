<?php

namespace App\Filament\Widgets;

use App\Models\Report;
use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class TotalReportsWidget extends BaseWidget
{
    protected function getStats(): array
    {
        $today = Carbon::today();
        
        $totalToday = Report::whereDate('created_at', $today)->count();
        $totalAman = Report::whereDate('created_at', $today)->where('condition_status', 'Aman/Bersih')->count();
        $totalKendala = Report::whereDate('created_at', $today)->where('condition_status', 'Ada Kendala')->count();

        return [
            Stat::make('Total Laporan Hari Ini', $totalToday)
                ->description('Total laporan yang masuk hari ini')
                ->descriptionIcon('heroicon-m-document-text')
                ->color('primary'),
            Stat::make('Laporan Aman', $totalAman)
                ->description('Kondisi Aman/Bersih')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),
            Stat::make('Laporan Kendala', $totalKendala)
                ->description('Terdapat Kendala')
                ->descriptionIcon('heroicon-m-exclamation-triangle')
                ->color('danger'),
        ];
    }
}
