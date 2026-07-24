<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('schedules', function (Blueprint $table) {
            $table->index(['user_id', 'shift_date', 'status']);
        });

        Schema::table('reports', function (Blueprint $table) {
            $table->index('created_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('schedules', function (Blueprint $table) {
            $table->dropIndex(['user_id', 'shift_date', 'status']);
        });

        Schema::table('reports', function (Blueprint $table) {
            $table->dropIndex(['created_at']);
        });
    }
};
