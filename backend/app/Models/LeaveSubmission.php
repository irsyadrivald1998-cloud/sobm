<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;

#[Fillable(['user_id', 'date', 'type', 'attachment_path'])]
class LeaveSubmission extends Model
{
    use HasFactory;
}
