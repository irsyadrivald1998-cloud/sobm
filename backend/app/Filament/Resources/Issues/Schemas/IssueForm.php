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
                Toggle::make('is_resolved')
                    ->required()
                    ->live(),
                Textarea::make('resolution_notes')
                    ->label('Catatan Penyelesaian')
                    ->visible(fn ($get) => $get('is_resolved'))
                    ->required(fn ($get) => $get('is_resolved'))
                    ->columnSpanFull(),
                DateTimePicker::make('resolved_at')
                    ->label('Diselesaikan Pada')
                    ->disabled()
                    ->visible(fn ($get) => $get('is_resolved')),
                Select::make('resolved_by')
                    ->label('Diselesaikan Oleh')
                    ->relationship('resolvedBy', 'name')
                    ->disabled()
                    ->visible(fn ($get) => $get('is_resolved')),
            ]);
    }
}
