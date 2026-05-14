<?php

namespace App\Filament\Widgets;

use App\Models\Issue;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class UnresolvedIssuesWidget extends BaseWidget
{
    protected function getStats(): array
    {
        $unresolvedCount = Issue::where('is_resolved', false)->count();

        return [
            Stat::make('Isu Belum Terselesaikan', $unresolvedCount)
                ->description('Jumlah masalah yang butuh tindak lanjut')
                ->descriptionIcon('heroicon-m-exclamation-circle')
                ->color('danger'),
        ];
    }
}
