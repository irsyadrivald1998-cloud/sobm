<?php

namespace App\Filament\Resources\Attendances\Tables;

use Carbon\Carbon;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Table;
use Filament\Forms\Components\DatePicker;

class AttendancesTable
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
                    ->date('d M Y')
                    ->sortable(),
                TextColumn::make('status')
                    ->label('Status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Hadir' => 'success',
                        'Terlambat' => 'warning',
                        'Alpa' => 'danger',
                        default => 'gray',
                    })
                    ->sortable(),
                TextColumn::make('clock_in_time')
                    ->label('Jam Masuk')
                    ->time('H:i')
                    ->placeholder('-'),
                ImageColumn::make('clock_in_photo_path')
                    ->label('Foto Masuk')
                    ->disk('public')
                    ->square(),
                TextColumn::make('clock_out_time')
                    ->label('Jam Keluar')
                    ->time('H:i')
                    ->placeholder('-'),
                ImageColumn::make('clock_out_photo_path')
                    ->label('Foto Keluar')
                    ->disk('public')
                    ->square(),
                TextColumn::make('notes')
                    ->label('Catatan')
                    ->limit(30)
                    ->placeholder('-'),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Status Kehadiran')
                    ->options([
                        'Hadir' => 'Hadir',
                        'Terlambat' => 'Terlambat',
                        'Alpa' => 'Alpa',
                    ]),
                Filter::make('date')
                    ->form([
                        DatePicker::make('created_from')->label('Mulai Tanggal'),
                        DatePicker::make('created_until')->label('Sampai Tanggal'),
                    ])
                    ->query(function ($query, array $data) {
                        return $query
                            ->when($data['created_from'], fn ($q) => $q->whereDate('date', '>=', $data['created_from']))
                            ->when($data['created_until'], fn ($q) => $q->whereDate('date', '<=', $data['created_until']));
                    }),
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
