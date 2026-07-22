<?php

namespace App\Policies;

use App\Models\Attendance;
use App\Models\User;

class AttendancePolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function view(User $user, Attendance $model): bool
    {
        return in_array($user->role, ['admin', 'viewer'], true);
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, Attendance $model): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, Attendance $model): bool
    {
        return $user->role === 'admin';
    }

    public function restore(User $user, Attendance $model): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, Attendance $model): bool
    {
        return $user->role === 'admin';
    }
}
