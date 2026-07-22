<?php

namespace App\Filament\Resources\Attendances\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\TimePicker;
use Filament\Schemas\Schema;

class AttendanceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->label('Karyawan')
                    ->relationship('user', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                DatePicker::make('date')
                    ->label('Tanggal')
                    ->default(now())
                    ->required(),
                Select::make('status')
                    ->label('Status Kehadiran')
                    ->options([
                        'Hadir' => 'Hadir',
                        'Terlambat' => 'Terlambat',
                        'Alpa' => 'Alpa',
                    ])
                    ->required(),
                TimePicker::make('clock_in_time')
                    ->label('Jam Masuk')
                    ->required(),
                TimePicker::make('clock_out_time')
                    ->label('Jam Keluar'),
                TextInput::make('clock_in_latitude')
                    ->label('Latitude Masuk')
                    ->numeric()
                    ->required(),
                TextInput::make('clock_in_longitude')
                    ->label('Longitude Masuk')
                    ->numeric()
                    ->required(),
                TextInput::make('clock_out_latitude')
                    ->label('Latitude Keluar')
                    ->numeric(),
                TextInput::make('clock_out_longitude')
                    ->label('Longitude Keluar')
                    ->numeric(),
                FileUpload::make('clock_in_photo_path')
                    ->label('Foto Masuk')
                    ->image()
                    ->directory('attendances/clock_in')
                    ->required(),
                FileUpload::make('clock_out_photo_path')
                    ->label('Foto Keluar')
                    ->image()
                    ->directory('attendances/clock_out'),
                Textarea::make('notes')
                    ->label('Catatan')
                    ->columnSpanFull(),
            ]);
    }
}
