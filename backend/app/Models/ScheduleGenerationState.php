<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;

#[Fillable(['role', 'last_user_index'])]
class ScheduleGenerationState extends Model
{
    use HasFactory;
}
