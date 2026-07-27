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
        Schema::create('attendance_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->time('shift_start');
            $table->time('shift_end');
            $table->enum('shift_type', ['pagi', 'siang', 'malam'])->default('pagi');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['user_id', 'date']);
            $table->index(['date', 'shift_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendance_schedules');
    }
};
