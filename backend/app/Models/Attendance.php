<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'user_id',
    'date',
    'clock_in_time',
    'clock_out_time',
    'clock_in_latitude',
    'clock_in_longitude',
    'clock_out_latitude',
    'clock_out_longitude',
    'clock_in_photo_path',
    'clock_out_photo_path',
    'status',
    'notes'
])]
class Attendance extends Model
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'date' => 'date:Y-m-d',
            'clock_in_time' => 'datetime:H:i:s',
            'clock_out_time' => 'datetime:H:i:s',
            'clock_in_latitude' => 'decimal:8',
            'clock_in_longitude' => 'decimal:8',
            'clock_out_latitude' => 'decimal:8',
            'clock_out_longitude' => 'decimal:8',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
