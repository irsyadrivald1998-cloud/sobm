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
        Schema::create('pengguna', function (Blueprint $table) {
            $table->id();
            $table->string('nik', 50)->unique();
            $table->string('nama', 255);
            $table->string('kata_sandi', 255);
            $table->enum('peran', ['admin', 'pemantau', 'kebersihan', 'teknisi', 'keamanan']);
            $table->timestamp('dibuat_pada')->useCurrent();
            $table->timestamp('diperbarui_pada')->useCurrent()->useCurrentOnUpdate();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pengguna');
    }
};
