<?php

namespace App\Filament\Resources\LeaveSubmissions;

use App\Filament\Resources\LeaveSubmissions\Pages;
use App\Filament\Resources\LeaveSubmissions\Schemas\LeaveSubmissionForm;
use App\Filament\Resources\LeaveSubmissions\Tables\LeaveSubmissionsTable;
use App\Models\LeaveSubmission;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class LeaveSubmissionResource extends Resource
{
    protected static ?string $model = LeaveSubmission::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendarDays;

    protected static ?string $navigationLabel = 'Cuti & Izin';

    protected static string|\UnitEnum|null $navigationGroup = 'Manajemen Pengguna';

    protected static ?int $navigationSort = 4;

    public static function form(Schema $schema): Schema
    {
        return LeaveSubmissionForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return LeaveSubmissionsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListLeaveSubmissions::route('/'),
            'create' => Pages\CreateLeaveSubmission::route('/create'),
            'edit' => Pages\EditLeaveSubmission::route('/{record}/edit'),
        ];
    }
}
