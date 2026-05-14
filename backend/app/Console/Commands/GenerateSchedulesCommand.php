<?php

namespace App\Console\Commands;

use App\Models\Checkpoint;
use App\Models\Schedule;
use App\Models\TaskCategory;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Console\Command;

class GenerateSchedulesCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'schedules:generate';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate operational schedules based on roles and rules.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $now = Carbon::now();
        $hour = $now->hour;
        $date = $now->toDateString();
        $time = $now->toTimeString();

        // 1. Housekeeping: Every 2 hours (08:00 - 18:00)
        if ($hour >= 8 && $hour <= 18 && $hour % 2 === 0) {
            $this->generateForRole('housekeeping', $date, $time);
        }

        // 2. Teknisi: Every 3 hours (08:00 - 18:00)
        // 08, 11, 14, 17
        if ($hour >= 8 && $hour <= 18 && ($hour - 8) % 3 === 0) {
            $this->generateForRole('teknisi', $date, $time);
        }

        // 3. Security: Every hour (22:00 - 05:00)
        if ($hour >= 22 || $hour <= 5) {
            $this->generateForRole('security', $date, $time);
        }

        $this->info('Schedules generation completed for current hour: ' . $hour);
    }

    private function generateForRole(string $role, string $date, string $time)
    {
        $users = User::where('role', $role)->get();
        if ($users->isEmpty()) return;

        $taskCategories = TaskCategory::where('target_role', $role)->get();
        if ($taskCategories->isEmpty()) return;

        // Simplified logic: Assign random checkpoint for each user for demo purposes, 
        // or generate schedules for all checkpoints and split among users.
        // Assuming we want a schedule for every checkpoint for the role.
        $checkpoints = Checkpoint::all();
        if ($checkpoints->isEmpty()) return;

        foreach ($checkpoints as $index => $checkpoint) {
            // Distribute round-robin among available users for this role
            $user = $users[$index % $users->count()];
            // Pick the first relevant task category as default
            $taskCategory = $taskCategories->first();

            // Check if already generated for this hour to avoid duplicates
            $exists = Schedule::where('user_id', $user->id)
                ->where('checkpoint_id', $checkpoint->id)
                ->where('task_category_id', $taskCategory->id)
                ->where('shift_date', $date)
                ->whereRaw('HOUR(scheduled_time) = ?', [Carbon::parse($time)->hour])
                ->exists();

            if (!$exists) {
                Schedule::create([
                    'user_id' => $user->id,
                    'checkpoint_id' => $checkpoint->id,
                    'task_category_id' => $taskCategory->id,
                    'shift_date' => $date,
                    'scheduled_time' => $time,
                    'status' => 'pending',
                ]);
            }
        }
    }
}
