<?php

namespace App\Filament\Resources\Issues\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Components\DateTimePicker;
use Filament\Schemas\Schema;

class IssueForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('report_id')
                    ->relationship('report', 'id')
                    ->required(),
                Textarea::make('issue_description')
                    ->required()
                    ->columnSpanFull(),
                Select::make('status')
                    ->options([
                        'open' => 'Open',
                        'in-progress' => 'In Progress',
                        'resolved' => 'Resolved',
                    ])
                    ->required()
                    ->live(),
                Toggle::make('is_resolved')
                    ->disabled()
                    ->dehydrated(false)
                    ->visible(false),
                Textarea::make('resolution_notes')
                    ->label('Catatan Penyelesaian')
                    ->visible(fn ($get) => $get('status') === 'resolved')
                    ->required(fn ($get) => $get('status') === 'resolved')
                    ->columnSpanFull(),
                DateTimePicker::make('resolved_at')
                    ->label('Diselesaikan Pada')
                    ->disabled()
                    ->visible(fn ($get) => $get('status') === 'resolved'),
                Select::make('resolved_by')
                    ->label('Diselesaikan Oleh')
                    ->relationship('resolvedBy', 'name')
                    ->disabled()
                    ->visible(fn ($get) => $get('status') === 'resolved'),
            ]);
    }
}
