<?php

namespace App\Filament\Resources\LeaveSubmissions\Schemas;

use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\FileUpload;
use Filament\Schemas\Schema;

class LeaveSubmissionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required()
                    ->searchable()
                    ->label('Karyawan'),
                Select::make('leave_type')
                    ->options([
                        'cuti' => 'Cuti',
                        'izin' => 'Izin',
                    ])
                    ->required()
                    ->label('Tipe'),
                DatePicker::make('start_date')
                    ->required()
                    ->label('Tanggal Mulai'),
                DatePicker::make('end_date')
                    ->required()
                    ->label('Tanggal Selesai'),
                Textarea::make('reason')
                    ->required()
                    ->label('Alasan')
                    ->rows(3),
                FileUpload::make('attachment_path')
                    ->label('Lampiran')
                    ->disk('public')
                    ->directory('leave_attachments')
                    ->acceptedFileTypes(['application/pdf', 'image/jpeg', 'image/png', 'image/jpg'])
                    ->maxSize(5120),
            ]);
    }
}
