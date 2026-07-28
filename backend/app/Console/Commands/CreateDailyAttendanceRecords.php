<?php

namespace App\Console\Commands;

use App\Models\Attendance;
use App\Models\AttendanceSchedule;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class CreateDailyAttendanceRecords extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'attendance:create-daily {--date= : Create attendance records for specific date (YYYY-MM-DD). Default: today}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Automatically create attendance records based on attendance schedules for the day';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $date = $this->option('date') 
            ? Carbon::parse($this->option('date')) 
            : Carbon::today('Asia/Jakarta');

        $this->info("Creating attendance records for date: {$date->toDateString()}");

        // Get all active attendance schedules for the date
        $schedules = AttendanceSchedule::where('date', $date->toDateString())
            ->where('is_active', true)
            ->get();

        $createdCount = 0;
        $skippedCount = 0;

        foreach ($schedules as $schedule) {
            DB::transaction(function () use ($schedule, &$createdCount, &$skippedCount) {
                // Check if attendance record already exists
                $existing = Attendance::where('user_id', $schedule->user_id)
                    ->where('date', $schedule->date)
                    ->lockForUpdate()
                    ->first();

                if ($existing) {
                    $skippedCount++;
                    $this->line("Attendance already exists for user {$schedule->user_id} on {$schedule->date}");
                    return;
                }

                // Create new attendance record
                Attendance::create([
                    'user_id' => $schedule->user_id,
                    'date' => $schedule->date,
                    'clock_in_time' => null,
                    'clock_out_time' => null,
                    'clock_in_latitude' => null,
                    'clock_in_longitude' => null,
                    'clock_out_latitude' => null,
                    'clock_out_longitude' => null,
                    'clock_in_photo_path' => null,
                    'clock_out_photo_path' => null,
                    'status' => 'Alpa', // Will be updated when user clocks in
                    'notes' => null,
                ]);

                $createdCount++;
                $this->line("Created attendance for user {$schedule->user_id} on {$schedule->date}");
            });
        }

        $this->info("Attendance records creation completed.");
        $this->info("Created: {$createdCount} records");
        $this->info("Skipped: {$skippedCount} records (already exist)");

        return Command::SUCCESS;
    }
}
