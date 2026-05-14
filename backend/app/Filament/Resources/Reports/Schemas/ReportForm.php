<?php

namespace App\Filament\Resources\Reports\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
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
                TextInput::make('photo_path')
                    ->required(),
                Select::make('condition_status')
                    ->options(['Aman/Bersih' => 'Aman/ bersih', 'Ada Kendala' => 'Ada kendala'])
                    ->required(),
                Textarea::make('notes')
                    ->columnSpanFull(),
            ]);
    }
}
