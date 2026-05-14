<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class TemuanMasalahSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();
        
        $temuanMasalah = [
            // Temuan dari laporan id 2 (Lobby - Keramik retak)
            [
                'id_laporan' => 2,
                'deskripsi_masalah' => 'Keramik retak di area dekat pintu masuk lobby. Ukuran retakan sekitar 15cm. Berpotensi membahayakan pengunjung.',
                'apakah_selesai' => true,
                'diselesaikan_pada' => $now->copy()->setTime(15, 30, 0),
            ],
            // Temuan dari laporan id 3 (AC Ruang Meeting)
            [
                'id_laporan' => 3,
                'deskripsi_masalah' => 'AC tidak dingin optimal. Filter kotor dan terlihat berdebu.',
                'apakah_selesai' => false,
                'diselesaikan_pada' => null,
            ],
            [
                'id_laporan' => 3,
                'deskripsi_masalah' => 'Indikator freon menunjukkan tekanan rendah. Perlu pengisian ulang freon.',
                'apakah_selesai' => false,
                'diselesaikan_pada' => null,
            ],
            // Temuan dari laporan id 4 (Plumbing Pantry)
            [
                'id_laporan' => 4,
                'deskripsi_masalah' => 'Kebocoran pada sambungan pipa wastafel. Air menetes perlahan ke bawah.',
                'apakah_selesai' => false,
                'diselesaikan_pada' => null,
            ],
            [
                'id_laporan' => 4,
                'deskripsi_masalah' => 'Kran air panas tidak berfungsi dengan baik. Perlu penggantian cartridge.',
                'apakah_selesai' => false,
                'diselesaikan_pada' => null,
            ],
        ];

        DB::table('temuan_masalah')->insert($temuanMasalah);
    }
}
