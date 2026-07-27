<?php

namespace App\Filament\Resources\AttendanceSchedules\Tables;

use Carbon\Carbon;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class AttendanceSchedulesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('date', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('Karyawan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('date')
                    ->label('Tanggal')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->translatedFormat('d M Y') : '-')
                    ->sortable(),
                TextColumn::make('shift_start')
                    ->label('Jam Masuk')
                    ->formatStateUsing(function ($state): string {
                        if ($state === null) {
                            return '-';
                        }
                        return Carbon::parse($state)->format('H:i');
                    })
                    ->sortable(),
                TextColumn::make('shift_end')
                    ->label('Jam Keluar')
                    ->formatStateUsing(function ($state): string {
                        if ($state === null) {
                            return '-';
                        }
                        return Carbon::parse($state)->format('H:i');
                    })
                    ->sortable(),
                TextColumn::make('shift_type')
                    ->label('Tipe Shift')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pagi'  => 'success',
                        'siang' => 'warning',
                        'malam' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pagi'  => 'Pagi',
                        'siang' => 'Siang',
                        'malam' => 'Malam',
                        default => $state,
                    }),
                IconColumn::make('is_active')
                    ->label('Aktif')
                    ->boolean()
                    ->trueIcon('heroicon-o-check-circle')
                    ->falseIcon('heroicon-o-x-circle')
                    ->trueColor('success')
                    ->falseColor('danger'),
                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->timezone(config('app.timezone'))->translatedFormat('d M Y, H:i') : '-')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('shift_type')
                    ->label('Tipe Shift')
                    ->options([
                        'pagi'  => 'Pagi',
                        'siang' => 'Siang',
                        'malam' => 'Malam',
                    ]),
                SelectFilter::make('is_active')
                    ->label('Status')
                    ->options([
                        '1' => 'Aktif',
                        '0' => 'Tidak Aktif',
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
