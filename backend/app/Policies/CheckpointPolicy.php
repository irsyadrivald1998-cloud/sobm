<?php

namespace App\Policies;

use App\Models\Checkpoint;
use App\Models\User;

class CheckpointPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function view(User $user, Checkpoint $model): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, Checkpoint $model): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, Checkpoint $model): bool
    {
        return $user->role === 'admin';
    }

    public function restore(User $user, Checkpoint $model): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, Checkpoint $model): bool
    {
        return $user->role === 'admin';
    }
}
