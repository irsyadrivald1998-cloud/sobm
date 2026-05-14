<?php

namespace App\Filament\Resources\TaskCategories\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class TaskCategoryForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('target_role')
                    ->options(['housekeeping' => 'Housekeeping', 'teknisi' => 'Teknisi', 'security' => 'Security'])
                    ->required(),
                TextInput::make('task_name')
                    ->required(),
            ]);
    }
}
