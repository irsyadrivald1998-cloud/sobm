<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['report_id', 'issue_description', 'is_resolved', 'resolved_at', 'resolved_by', 'resolution_notes'])]
class Issue extends Model
{
    use HasFactory, SoftDeletes;

    protected static function booted()
    {
        static::saving(function ($issue) {
            if ($issue->isDirty('is_resolved') && $issue->is_resolved) {
                $issue->resolved_at = $issue->resolved_at ?? now();
                $issue->resolved_by = $issue->resolved_by ?? \Illuminate\Support\Facades\Auth::id();
            } elseif ($issue->isDirty('is_resolved') && !$issue->is_resolved) {
                $issue->resolved_at = null;
                $issue->resolved_by = null;
                $issue->resolution_notes = null;
            }
        });
    }

    protected function casts(): array
    {
        return [
            'is_resolved' => 'boolean',
            'resolved_at' => 'datetime',
        ];
    }

    public function report(): BelongsTo
    {
        return $this->belongsTo(Report::class);
    }

    public function resolvedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }
}
