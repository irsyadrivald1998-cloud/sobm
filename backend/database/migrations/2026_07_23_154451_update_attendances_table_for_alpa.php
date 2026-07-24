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
        Schema::table('attendances', function (Blueprint $table) {
            $table->time('clock_in_time')->nullable()->change();
            $table->decimal('clock_in_latitude', 10, 8)->nullable()->change();
            $table->decimal('clock_in_longitude', 11, 8)->nullable()->change();
            $table->string('clock_in_photo_path')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->time('clock_in_time')->nullable(false)->change();
            $table->decimal('clock_in_latitude', 10, 8)->nullable(false)->change();
            $table->decimal('clock_in_longitude', 11, 8)->nullable(false)->change();
            $table->string('clock_in_photo_path')->nullable(false)->change();
        });
    }
};
