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
        Schema::create('titik_kontrol', function (Blueprint $table) {
            $table->id();
            $table->foreignId('id_area')->constrained('area')->onDelete('cascade');
            $table->string('nama_titik', 255);
            $table->decimal('lintang', 10, 8);
            $table->decimal('bujur', 11, 8);
            $table->unsignedInteger('radius_meter')->default(10);
            $table->timestamp('dibuat_pada')->useCurrent();
            $table->timestamp('diperbarui_pada')->useCurrent()->useCurrentOnUpdate();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('titik_kontrol');
    }
};
