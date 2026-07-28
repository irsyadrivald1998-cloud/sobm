<?php

namespace App\Filament\Resources\LeaveSubmissions\Pages;

use App\Filament\Resources\LeaveSubmissions\LeaveSubmissionResource;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreateLeaveSubmission extends CreateRecord
{
    protected static string $resource = LeaveSubmissionResource::class;
}
