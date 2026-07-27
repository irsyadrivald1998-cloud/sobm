<?php

namespace App\Filament\Resources\AttendanceSchedules\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TimePicker;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class AttendanceScheduleForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->relationship('user', 'name')
                    ->label('Karyawan')
                    ->searchable()
                    ->preload()
                    ->required(),
                DatePicker::make('date')
                    ->label('Tanggal')
                    ->required(),
                TimePicker::make('shift_start')
                    ->label('Jam Masuk')
                    ->seconds(false)
                    ->required(),
                TimePicker::make('shift_end')
                    ->label('Jam Keluar')
                    ->seconds(false)
                    ->required(),
                Select::make('shift_type')
                    ->label('Tipe Shift')
                    ->options([
                        'pagi'  => 'Pagi',
                        'siang' => 'Siang',
                        'malam' => 'Malam',
                    ])
                    ->default('pagi')
                    ->required(),
                Toggle::make('is_active')
                    ->label('Aktif')
                    ->default(true),
            ]);
    }
}
