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
        Schema::create('laporan', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_jadwal')->unique()->constrained('jadwal')->onDelete('cascade');
            $table->dateTime('waktu_lapor');
            $table->decimal('lintang_lapor', 10, 8);
            $table->decimal('bujur_lapor', 11, 8);
            $table->string('lokasi_file_foto', 255)->nullable();
            $table->enum('status_kondisi', ['Aman/Bersih', 'Ada Kendala']);
            $table->text('catatan')->nullable();
            $table->timestamp('dibuat_pada')->useCurrent();
            $table->timestamp('diperbarui_pada')->useCurrent()->useCurrentOnUpdate();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('laporan');
    }
};
