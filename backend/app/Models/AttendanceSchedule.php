<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'date', 'shift_start', 'shift_end', 'shift_type', 'is_active'])]
class AttendanceSchedule extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'date' => 'date:Y-m-d',
            'shift_start' => 'datetime:H:i:s',
            'shift_end' => 'datetime:H:i:s',
            'is_active' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForDate($query, $date)
    {
        return $query->where('date', $date);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
