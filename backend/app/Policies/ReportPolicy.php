<?php

namespace App\Policies;

use App\Models\Report;
use App\Models\User;

class ReportPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function view(User $user, Report $model): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, Report $model): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, Report $model): bool
    {
        return $user->role === 'admin';
    }

    public function restore(User $user, Report $model): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, Report $model): bool
    {
        return $user->role === 'admin';
    }
}
