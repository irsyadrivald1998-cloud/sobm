<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Admin
        User::create([
            'employee_id' => 'admin_001',
            'name' => 'Super Admin',
            'password' => Hash::make('password123'),
            'role' => 'admin',
        ]);

        // Worker
        User::create([
            'employee_id' => 'hk_001',
            'name' => 'Budi Housekeeping',
            'password' => Hash::make('password123'),
            'role' => 'housekeeping',
        ]);
    }
}
