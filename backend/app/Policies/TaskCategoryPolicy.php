<?php

namespace App\Policies;

use App\Models\TaskCategory;
use App\Models\User;

class TaskCategoryPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function view(User $user, TaskCategory $model): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, TaskCategory $model): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, TaskCategory $model): bool
    {
        return $user->role === 'admin';
    }

    public function restore(User $user, TaskCategory $model): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, TaskCategory $model): bool
    {
        return $user->role === 'admin';
    }
}
