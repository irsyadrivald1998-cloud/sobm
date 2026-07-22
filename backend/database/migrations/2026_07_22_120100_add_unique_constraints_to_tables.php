<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('schedules', function (Blueprint $table) {
            $table->unique(['user_id', 'checkpoint_id', 'task_category_id', 'shift_date', 'scheduled_time'], 'schedules_unique_assignment');
        });

        Schema::table('issues', function (Blueprint $table) {
            $table->unique('report_id');
        });
    }

    public function down(): void
    {
        Schema::table('schedules', function (Blueprint $table) {
            $table->dropUnique('schedules_unique_assignment');
        });

        Schema::table('issues', function (Blueprint $table) {
            $table->dropUnique(['report_id']);
        });
    }
};
