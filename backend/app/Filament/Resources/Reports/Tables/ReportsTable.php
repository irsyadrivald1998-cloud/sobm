<?php

namespace App\Filament\Resources\Reports\Tables;

use Carbon\Carbon;
use Filament\Actions\ViewAction;
use Filament\Forms\Components\DatePicker;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ReportsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->modifyQueryUsing(fn (Builder $query) => $query->with(['schedule.user', 'schedule.checkpoint', 'issue']))
            ->defaultSort('check_in_time', 'desc')
            ->columns([
                TextColumn::make('schedule.id')
                    ->label('Jadwal')
                    ->sortable(),
                TextColumn::make('schedule.user.name')
                    ->label('Pekerja')
                    ->searchable(),
                TextColumn::make('schedule.user.role')
                    ->label('Role')
                    ->badge()
                    ->toggleable(),
                TextColumn::make('check_in_time')
                    ->label('Check-in')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->timezone(config('app.timezone'))->translatedFormat('d M Y, H:i') : '—')
                    ->sortable(),
                TextColumn::make('check_in_latitude')
                    ->label('Lat')
                    ->numeric(decimalPlaces: 6)
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('check_in_longitude')
                    ->label('Lon')
                    ->numeric(decimalPlaces: 6)
                    ->toggleable(isToggledHiddenByDefault: true),
                ImageColumn::make('photo_path')
                    ->label('Foto')
                    ->disk('public')
                    ->height(48)
                    ->square(),
                TextColumn::make('condition_status')
                    ->label('Kondisi')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Aman/Bersih' => 'success',
                        'Ada Kendala' => 'danger',
                        default => 'gray',
                    }),
                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->timezone(config('app.timezone'))->translatedFormat('d M Y, H:i') : '—')
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Filter::make('check_in_range')
                    ->label('Rentang tanggal check-in')
                    ->schema([
                        DatePicker::make('from')
                            ->label('Dari'),
                        DatePicker::make('until')
                            ->label('Sampai'),
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        return $query
                            ->when(
                                filled($data['from'] ?? null),
                                fn (Builder $q): Builder => $q->whereDate('check_in_time', '>=', $data['from'])
                            )
                            ->when(
                                filled($data['until'] ?? null),
                                fn (Builder $q): Builder => $q->whereDate('check_in_time', '<=', $data['until'])
                            );
                    }),
                SelectFilter::make('worker_role')
                    ->label('Role pekerja')
                    ->options([
                        'housekeeping' => 'Housekeeping',
                        'teknisi' => 'Teknisi',
                        'security' => 'Security',
                    ])
                    ->query(function (Builder $query, array $data): Builder {
                        $role = $data['value'] ?? null;

                        if (! filled($role)) {
                            return $query;
                        }

                        return $query->whereHas(
                            'schedule.user',
                            fn (Builder $q) => $q->where('role', $role)
                        );
                    }),
                SelectFilter::make('condition_status')
                    ->label('Status kondisi')
                    ->options([
                        'Aman/Bersih' => 'Aman/Bersih',
                        'Ada Kendala' => 'Ada Kendala',
                    ])
                    ->attribute('condition_status'),
            ])
            ->recordActions([
                ViewAction::make(),
            ]);
    }
}
