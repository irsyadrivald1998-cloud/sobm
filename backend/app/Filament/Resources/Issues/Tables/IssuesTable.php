<?php

namespace App\Filament\Resources\Issues\Tables;

use Carbon\Carbon;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class IssuesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('report.schedule.user.name')
                    ->label('Pekerja')
                    ->searchable(),
                TextColumn::make('report.schedule.checkpoint.name')
                    ->label('Checkpoint')
                    ->searchable(),
                TextColumn::make('issue_description')
                    ->label('Deskripsi Kendala')
                    ->limit(60)
                    ->wrap(),
                IconColumn::make('is_resolved')
                    ->label('Sudah Diselesaikan')
                    ->boolean()
                    ->trueColor('success')
                    ->falseColor('danger'),
                TextColumn::make('created_at')
                    ->label('Dilaporkan')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->timezone(config('app.timezone'))->translatedFormat('d M Y, H:i') : '-')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('is_resolved')
                    ->label('Status Kendala')
                    ->options([
                        '1' => 'Sudah Diselesaikan',
                        '0' => 'Belum Diselesaikan',
                    ])
                    ->attribute('is_resolved'),
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
