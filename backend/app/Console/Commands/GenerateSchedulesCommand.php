<?php

namespace App\Console\Commands;

use App\Models\Checkpoint;
use App\Models\Schedule;
use App\Models\TaskCategory;
use App\Models\User;
use App\Models\ScheduleGenerationState;
use App\Models\LeaveSubmission;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

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

        // 4. OSB & Resepsionis: Daily 08:00-17:00
        // Generate only once per day at 08:00
        if ($hour === 8) {
            $this->generateForRole('osb', $date, '08:00:00');
            $this->generateForRole('resepsionis', $date, '08:00:00');
        }

        // Admin, BM, User: Tidak ada jadwal patroli/checkpoint.

        $this->info('Schedules generation completed for current hour: ' . $hour);
    }

    private function generateForRole(string $role, string $date, string $time)
    {
        $users = User::where('role', $role)
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date);
            })
            ->get();
        if ($users->isEmpty()) return;

        $taskCategories = TaskCategory::where('target_role', $role)->get();
        if ($taskCategories->isEmpty()) return;

        $checkpoints = Checkpoint::all();
        if ($checkpoints->isEmpty()) return;

        // Use transaction to prevent race conditions
        DB::transaction(function () use ($role, $users, $taskCategories, $checkpoints, $date, $time) {
            // Get or create state for round-robin with lock
            $state = ScheduleGenerationState::where('role', $role)
                ->lockForUpdate()
                ->first();

            if (!$state) {
                $state = ScheduleGenerationState::create([
                    'role' => $role,
                    'last_user_index' => 0
                ]);
            }

            $currentIndex = $state->last_user_index;

            foreach ($checkpoints as $checkpoint) {
                // Distribute round-robin among available users for this role
                $user = $users[$currentIndex % $users->count()];
                $taskCategory = $taskCategories->first();

                // Check if already generated for this hour
                $exists = Schedule::where('user_id', $user->id)
                    ->where('checkpoint_id', $checkpoint->id)
                    ->where('task_category_id', $taskCategory->id)
                    ->where('shift_date', $date)
                    ->whereRaw('HOUR(scheduled_time) = ?', [Carbon::parse($time)->hour])
                    ->lockForUpdate()
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

                $currentIndex++;
            }

            // Save state
            $state->update(['last_user_index' => $currentIndex % $users->count()]);
        });
    }
}
