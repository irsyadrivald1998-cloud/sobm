<?php

namespace App\Filament\Resources\LeaveSubmissions\Pages;

use App\Filament\Resources\LeaveSubmissions\LeaveSubmissionResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditLeaveSubmission extends EditRecord
{
    protected static string $resource = LeaveSubmissionResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
