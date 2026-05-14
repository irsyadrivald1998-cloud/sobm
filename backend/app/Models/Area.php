<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'description'])]
class Area extends Model
{
    use HasFactory;

    public function checkpoints(): HasMany
    {
        return $this->hasMany(Checkpoint::class);
    }
}
