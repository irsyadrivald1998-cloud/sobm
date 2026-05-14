<?php

namespace App\Filament\Resources\Schedules\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TimePicker;
use Filament\Schemas\Schema;

class ScheduleForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required(),
                Select::make('checkpoint_id')
                    ->relationship('checkpoint', 'name')
                    ->required(),
                Select::make('task_category_id')
                    ->relationship('taskCategory', 'id')
                    ->required(),
                DatePicker::make('shift_date')
                    ->required(),
                TimePicker::make('scheduled_time')
                    ->required(),
                Select::make('status')
                    ->options(['pending' => 'Pending', 'completed' => 'Completed'])
                    ->default('pending')
                    ->required(),
            ]);
    }
}
