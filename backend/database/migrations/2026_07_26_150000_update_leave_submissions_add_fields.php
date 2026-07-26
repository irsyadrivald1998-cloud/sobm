<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('leave_submissions', function (Blueprint $table) {
            // Tambah kolom baru setelah kolom yang sudah ada
            $table->string('leave_type')->after('user_id')->nullable();
            $table->date('start_date')->after('leave_type')->nullable();
            $table->date('end_date')->after('start_date')->nullable();
            $table->text('reason')->after('end_date')->nullable();

            // Buat attachment_path nullable (karena cuti tidak wajib lampiran)
            $table->string('attachment_path')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('leave_submissions', function (Blueprint $table) {
            $table->dropColumn(['leave_type', 'start_date', 'end_date', 'reason']);
            $table->string('attachment_path')->nullable(false)->change();
        });
    }
};
