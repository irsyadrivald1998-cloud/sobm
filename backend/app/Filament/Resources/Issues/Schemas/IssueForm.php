<?php

namespace App\Filament\Resources\Issues\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
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
                    ->required(),
            ]);
    }
}
