<?php

namespace App\Filament\Resources\Schedules\Tables;

use Carbon\Carbon;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class SchedulesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('shift_date', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('Pekerja')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('user.role')
                    ->label('Role')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'housekeeping' => 'info',
                        'teknisi'      => 'warning',
                        'security'     => 'danger',
                        default        => 'gray',
                    })
                    ->toggleable(),
                TextColumn::make('checkpoint.name')
                    ->label('Checkpoint')
                    ->searchable(),
                TextColumn::make('taskCategory.task_name')
                    ->label('Kategori Tugas')
                    ->searchable(),
                TextColumn::make('shift_date')
                    ->label('Tanggal')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->translatedFormat('d M Y') : '-')
                    ->sortable(),
                TextColumn::make('scheduled_time')
                    ->label('Jam Patroli')
                    ->formatStateUsing(function ($state): string {
                        if ($state === null) {
                            return '-';
                        }

                        return Carbon::parse($state)->format('H:i');
                    })
                    ->sortable(),
                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending'   => 'warning',
                        'completed' => 'success',
                        default     => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending'   => 'Menunggu',
                        'completed' => 'Selesai',
                        default     => $state,
                    }),
                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->timezone(config('app.timezone'))->translatedFormat('d M Y, H:i') : '-')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Status')
                    ->options([
                        'pending'   => 'Menunggu',
                        'completed' => 'Selesai',
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
