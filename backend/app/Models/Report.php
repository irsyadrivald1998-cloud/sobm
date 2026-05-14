<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['schedule_id', 'check_in_time', 'check_in_latitude', 'check_in_longitude', 'photo_path', 'condition_status', 'notes'])]
class Report extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'check_in_time' => 'datetime',
            'check_in_latitude' => 'decimal:8',
            'check_in_longitude' => 'decimal:8',
        ];
    }

    public function schedule(): BelongsTo
    {
        return $this->belongsTo(Schedule::class);
    }

    public function issue(): HasOne
    {
        return $this->hasOne(Issue::class);
    }
}
