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
        // 1. Pastikan users punya role (sudah ada, pastikan nullable false)
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->nullable(false)->change();
        });

        // 2. Pastikan reports.schedule_id nullable sesuai rencana OSB/Resepsionis
        Schema::table('reports', function (Blueprint $table) {
            $table->unsignedBigInteger('schedule_id')->nullable()->change();
        });

        // 3. Tambah kolom yang mungkin kurang di skema existing
        Schema::table('reports', function (Blueprint $table) {
             if (!Schema::hasColumn('reports', 'work_description')) {
                 $table->string('work_description')->after('schedule_id');
             }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Kebalikan dari up
        Schema::table('reports', function (Blueprint $table) {
            $table->unsignedBigInteger('schedule_id')->nullable(false)->change();
        });
    }
};
