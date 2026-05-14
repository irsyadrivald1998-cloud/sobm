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
        Schema::create('jadwal', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_pengguna')->constrained('pengguna')->onDelete('restrict');
            $table->foreignId('id_titik_kontrol')->constrained('titik_kontrol')->onDelete('restrict');
            $table->foreignId('id_kategori_tugas')->constrained('kategori_tugas')->onDelete('restrict');
            $table->dateTime('waktu_mulai');
            $table->dateTime('waktu_batas_selesai');
            $table->enum('status', ['menunggu', 'selesai', 'terlewat'])->default('menunggu');
            $table->timestamp('dibuat_pada')->useCurrent();
            $table->timestamp('diperbarui_pada')->useCurrent()->useCurrentOnUpdate();
            
            // Index untuk performa query
            $table->index('waktu_mulai');
            $table->index('waktu_batas_selesai');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('jadwal');
    }
};
