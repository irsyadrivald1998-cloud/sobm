<?php

namespace App\Filament\Resources\Reports\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class ReportForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('schedule_id')
                    ->relationship('schedule', 'id')
                    ->required(),
                DateTimePicker::make('check_in_time')
                    ->required(),
                TextInput::make('check_in_latitude')
                    ->required()
                    ->numeric(),
                TextInput::make('check_in_longitude')
                    ->required()
                    ->numeric(),
                FileUpload::make('photo_path')
                    ->label('Foto')
                    ->disk('public')
                    ->directory('reports')
                    ->image()
                    ->disabled()
                    ->dehydrated(false),
                Select::make('condition_status')
                    ->options([
                        'Aman/Bersih' => 'Aman/Bersih',
                        'Ada Kendala' => 'Ada Kendala',
                    ])
                    ->required(),
                Textarea::make('notes')
                    ->columnSpanFull(),
            ]);
    }
}
