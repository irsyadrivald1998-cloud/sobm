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
        Schema::create('temuan_masalah', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_laporan')->constrained('laporan')->onDelete('cascade');
            $table->text('deskripsi_masalah');
            $table->boolean('apakah_selesai')->default(false);
            $table->dateTime('diselesaikan_pada')->nullable();
            $table->timestamp('dibuat_pada')->useCurrent();
            $table->timestamp('diperbarui_pada')->useCurrent()->useCurrentOnUpdate();
            
            // Index untuk performa query
            $table->index('apakah_selesai');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('temuan_masalah');
    }
};
