<?php

namespace App\Console\Commands;

use App\Models\AttendanceSchedule;
use App\Models\User;
use App\Models\LeaveSubmission;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class GenerateAttendanceSchedulesCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'attendance-schedules:generate {--date= : Generate for specific date (YYYY-MM-DD). Default: tomorrow}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate attendance schedules for workers based on their roles and shift patterns.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $date = $this->option('date') 
            ? Carbon::parse($this->option('date')) 
            : Carbon::tomorrow();

        $this->info("Generating attendance schedules for date: {$date->toDateString()}");

        // Generate schedules for each role
        $this->generateForHousekeeping($date);
        $this->generateForTeknisi($date);
        $this->generateForSecurity($date);
        $this->generateForOSB($date);
        $this->generateForResepsionis($date);
        $this->generateForBM($date);

        $this->info('Attendance schedules generation completed.');
    }

    private function generateForHousekeeping(Carbon $date)
    {
        $this->info('Generating schedules for Housekeeping...');

        $users = User::where('role', 'housekeeping')
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date->toDateString());
            })
            ->get();

        foreach ($users as $user) {
            // Housekeeping: Shift pagi 08:00-17:00
            $this->createSchedule($user, $date, '08:00:00', '17:00:00', 'pagi');
        }

        $this->info("Generated {$users->count()} schedules for Housekeeping.");
    }

    private function generateForTeknisi(Carbon $date)
    {
        $this->info('Generating schedules for Teknisi...');

        $users = User::where('role', 'teknisi')
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date->toDateString());
            })
            ->get();

        foreach ($users as $user) {
            // Teknisi: Shift pagi 08:00-17:00
            $this->createSchedule($user, $date, '08:00:00', '17:00:00', 'pagi');
        }

        $this->info("Generated {$users->count()} schedules for Teknisi.");
    }

    private function generateForSecurity(Carbon $date)
    {
        $this->info('Generating schedules for Security...');

        $users = User::where('role', 'security')
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date->toDateString());
            })
            ->get();

        foreach ($users as $user) {
            // Security: 3 shifts per day
            // Shift pagi: 06:00-14:00
            // Shift siang: 14:00-22:00
            // Shift malam: 22:00-06:00 (next day)

            // Generate 3 schedules for each security personnel
            $this->createSchedule($user, $date, '06:00:00', '14:00:00', 'pagi');
            $this->createSchedule($user, $date, '14:00:00', '22:00:00', 'siang');
            $this->createSchedule($user, $date, '22:00:00', '06:00:00', 'malam');
        }

        $schedulesCount = $users->count() * 3;
        $this->info("Generated {$schedulesCount} schedules for Security (3 shifts per person).");
    }

    private function generateForOSB(Carbon $date)
    {
        $this->info('Generating schedules for OSB...');

        $users = User::where('role', 'osb')
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date->toDateString());
            })
            ->get();

        foreach ($users as $user) {
            // OSB: Shift pagi 08:00-17:00
            $this->createSchedule($user, $date, '08:00:00', '17:00:00', 'pagi');
        }

        $this->info("Generated {$users->count()} schedules for OSB.");
    }

    private function generateForResepsionis(Carbon $date)
    {
        $this->info('Generating schedules for Resepsionis...');

        $users = User::where('role', 'resepsionis')
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date->toDateString());
            })
            ->get();

        foreach ($users as $user) {
            // Resepsionis: Shift pagi 08:00-17:00
            $this->createSchedule($user, $date, '08:00:00', '17:00:00', 'pagi');
        }

        $this->info("Generated {$users->count()} schedules for Resepsionis.");
    }

    private function generateForBM(Carbon $date)
    {
        $this->info('Generating schedules for BM...');

        $users = User::where('role', 'bm')
            ->whereDoesntHave('leaveSubmissions', function ($query) use ($date) {
                $query->where('date', $date->toDateString());
            })
            ->get();

        foreach ($users as $user) {
            // BM: Shift pagi 08:00-17:00
            $this->createSchedule($user, $date, '08:00:00', '17:00:00', 'pagi');
        }

        $this->info("Generated {$users->count()} schedules for BM.");
    }

    private function createSchedule(User $user, Carbon $date, string $shiftStart, string $shiftEnd, string $shiftType)
    {
        DB::transaction(function () use ($user, $date, $shiftStart, $shiftEnd, $shiftType) {
            // Check if schedule already exists
            $exists = AttendanceSchedule::where('user_id', $user->id)
                ->where('date', $date->toDateString())
                ->where('shift_start', $shiftStart)
                ->lockForUpdate()
                ->exists();

            if (!$exists) {
                AttendanceSchedule::create([
                    'user_id' => $user->id,
                    'date' => $date->toDateString(),
                    'shift_start' => $shiftStart,
                    'shift_end' => $shiftEnd,
                    'shift_type' => $shiftType,
                    'is_active' => true,
                ]);
            }
        });
    }
}
