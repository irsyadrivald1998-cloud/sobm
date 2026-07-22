<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['user_id', 'checkpoint_id', 'task_category_id', 'shift_date', 'scheduled_time', 'status'])]
class Schedule extends Model
{
    use HasFactory, SoftDeletes;

    protected static function booted()
    {
        static::saving(function ($schedule) {
            $user = $schedule->user;
            $taskCategory = $schedule->taskCategory;
            if ($user && $taskCategory) {
                if ($user->role !== $taskCategory->target_role) {
                    throw new \InvalidArgumentException("Role user ({$user->role}) tidak sesuai dengan target role kategori tugas ({$taskCategory->target_role}).");
                }
            }
        });
    }

    protected function casts(): array
    {
        return [
            'shift_date' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function checkpoint(): BelongsTo
    {
        return $this->belongsTo(Checkpoint::class);
    }

    public function taskCategory(): BelongsTo
    {
        return $this->belongsTo(TaskCategory::class);
    }

    public function report(): HasOne
    {
        return $this->hasOne(Report::class);
    }
}
