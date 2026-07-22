<?php

namespace App\Filament\Resources\Reports;

use App\Filament\Resources\Reports\Pages\CreateReport;
use App\Filament\Resources\Reports\Pages\EditReport;
use App\Filament\Resources\Reports\Pages\ListReports;
use App\Filament\Resources\Reports\Pages\ViewReport;
use App\Filament\Resources\Reports\Schemas\ReportForm;
use App\Filament\Resources\Reports\Tables\ReportsTable;
use App\Models\Report;
use BackedEnum;
use Carbon\Carbon;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;

class ReportResource extends Resource
{
    protected static ?string $model = Report::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedDocumentText;

    protected static ?string $navigationLabel = 'Laporan';

    protected static string|\UnitEnum|null $navigationGroup = 'Operasional';

    protected static ?int $navigationSort = 2;

    public static function canCreate(): bool
    {
        return false;
    }

    public static function canEdit(?Model $record = null): bool
    {
        return false;
    }

    public static function canDelete(?Model $record = null): bool
    {
        return false;
    }

    public static function form(Schema $schema): Schema
    {
        return ReportForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('schedule.user.name')
                    ->label('Pekerja'),
                TextEntry::make('schedule.user.role')
                    ->label('Role')
                    ->badge(),
                TextEntry::make('schedule.checkpoint.name')
                    ->label('Checkpoint'),
                TextEntry::make('schedule.shift_date')
                    ->label('Tanggal Jadwal')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->translatedFormat('d M Y') : '-'),
                TextEntry::make('schedule.scheduled_time')
                    ->label('Jam Patroli')
                    ->formatStateUsing(function ($state): string {
                        if ($state === null) {
                            return '-';
                        }

                        return Carbon::parse($state)->format('H:i');
                    }),
                TextEntry::make('check_in_time')
                    ->label('Waktu Check-in')
                    ->formatStateUsing(fn ($state) => $state ? Carbon::parse($state)->timezone(config('app.timezone'))->translatedFormat('d M Y, H:i') : '-'),
                TextEntry::make('check_in_latitude')
                    ->label('Latitude'),
                TextEntry::make('check_in_longitude')
                    ->label('Longitude'),
                ImageEntry::make('photo_path')
                    ->label('Foto')
                    ->disk('public')
                    ->imageWidth(420),
                TextEntry::make('condition_status')
                    ->label('Kondisi')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'Aman/Bersih' => 'success',
                        'Ada Kendala' => 'danger',
                        default       => 'gray',
                    }),
                TextEntry::make('notes')
                    ->label('Catatan')
                    ->columnSpanFull(),
                TextEntry::make('issue.issue_description')
                    ->label('Deskripsi Kendala')
                    ->columnSpanFull()
                    ->visible(fn (Report $record): bool => $record->condition_status === 'Ada Kendala'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return ReportsTable::configure($table);
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
            'index'  => ListReports::route('/'),
            'create' => CreateReport::route('/create'),
            'view'   => ViewReport::route('/{record}'),
            'edit'   => EditReport::route('/{record}/edit'),
        ];
    }
}
