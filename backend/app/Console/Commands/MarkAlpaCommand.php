<?php

namespace App\Console\Commands;

use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('attendances:mark-alpa')]
#[Description('Mark absent users as Alpa')]
class MarkAlpaCommand extends Command
{
    public function handle()
    {
        $today = \Carbon\Carbon::today();

        $users = \App\Models\User::whereNotIn('role', ['admin', 'user'])
            ->whereDoesntHave('attendances', function ($query) use ($today) {
                $query->where('date', $today);
            })
            ->get();

        foreach ($users as $user) {
            \App\Models\Attendance::updateOrCreate(
                ['user_id' => $user->id, 'date' => $today],
                ['status' => 'Alpa']
            );
        }

        $this->info('Marked absent users as Alpa for today.');
    }
}
