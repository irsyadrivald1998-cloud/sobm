<?php

namespace App\Policies;

use App\Models\Area;
use App\Models\User;

class AreaPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function view(User $user, Area $model): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, Area $model): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, Area $model): bool
    {
        return $user->role === 'admin';
    }

    public function restore(User $user, Area $model): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, Area $model): bool
    {
        return $user->role === 'admin';
    }
}
