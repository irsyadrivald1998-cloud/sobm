<?php

namespace App\Policies;

use App\Models\Issue;
use App\Models\User;

class IssuePolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function view(User $user, Issue $model): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, Issue $model): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, Issue $model): bool
    {
        return $user->role === 'admin';
    }

    public function restore(User $user, Issue $model): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, Issue $model): bool
    {
        return $user->role === 'admin';
    }
}
