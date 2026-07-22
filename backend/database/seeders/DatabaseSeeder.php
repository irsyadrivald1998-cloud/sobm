<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Area;
use App\Models\Checkpoint;
use App\Models\TaskCategory;
use App\Models\Schedule;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Seed Admin
        $admin = User::updateOrCreate(
            ['employee_id' => 'admin_001'],
            [
                'name' => 'Super Admin',
                'password' => Hash::make(env('SEEDER_DEFAULT_PASSWORD', 'password123')),
                'role' => 'admin',
            ]
        );

        // 2. Seed Housekeeping Worker
        $worker = User::updateOrCreate(
            ['employee_id' => 'hk_001'],
            [
                'name' => 'Budi Housekeeping',
                'password' => Hash::make(env('SEEDER_DEFAULT_PASSWORD', 'password123')),
                'role' => 'housekeeping',
            ]
        );

        // 3. Seed Area
        $area = Area::updateOrCreate(
            ['name' => 'Kampus Universitas Jayanusa'],
            ['description' => 'Gedung utama Universitas Jayanusa']
        );

        // 4. Seed Checkpoint
        $checkpoint = Checkpoint::updateOrCreate(
            [
                'area_id' => $area->id,
                'name' => 'Lobby Universitas Jayanusa',
            ],
            [
                'latitude' => -0.9432688514029636,
                'longitude' => 100.353963921057,
                'radius_meter' => 25000, // 25 km radius
            ]
        );

        // 5. Seed Task Category
        $taskCategory = TaskCategory::updateOrCreate(
            [
                'target_role' => 'housekeeping',
                'task_name' => 'Sapu dan Pel Lobby Utama',
            ]
        );

        // 6. Seed Schedule for Today
        Schedule::updateOrCreate(
            [
                'user_id' => $worker->id,
                'checkpoint_id' => $checkpoint->id,
                'shift_date' => Carbon::today()->format('Y-m-d'),
            ],
            [
                'task_category_id' => $taskCategory->id,
                'scheduled_time' => '08:00:00',
                'status' => 'pending',
            ]
        );

        // 7. Seed Schedule for Tomorrow (Example)
        Schedule::updateOrCreate(
            [
                'user_id' => $worker->id,
                'checkpoint_id' => $checkpoint->id,
                'shift_date' => Carbon::tomorrow()->format('Y-m-d'),
            ],
            [
                'task_category_id' => $taskCategory->id,
                'scheduled_time' => '09:30:00',
                'status' => 'pending',
            ]
        );
    }
}
