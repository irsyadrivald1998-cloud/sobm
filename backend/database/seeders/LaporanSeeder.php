<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class LaporanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();
        
        $laporan = [
            // Laporan untuk jadwal yang sudah selesai
            [
                'id_jadwal' => 1, // Siti - Pembersihan Toilet
                'waktu_lapor' => $now->copy()->setTime(8, 45, 0),
                'lintang_lapor' => -6.20885100,
                'bujur_lapor' => 106.84575100,
                'lokasi_file_foto' => 'laporan/toilet_lantai1_20240101_0845.jpg',
                'status_kondisi' => 'Aman/Bersih',
                'catatan' => 'Toilet sudah dibersihkan dengan baik. Semua perlengkapan lengkap.',
            ],
            [
                'id_jadwal' => 2, // Siti - Pembersihan Lobby
                'waktu_lapor' => $now->copy()->setTime(10, 15, 0),
                'lintang_lapor' => -6.20880050,
                'bujur_lapor' => 106.84570050,
                'lokasi_file_foto' => 'laporan/lobby_20240101_1015.jpg',
                'status_kondisi' => 'Ada Kendala',
                'catatan' => 'Lobby sudah bersih, namun ditemukan keramik retak di area dekat pintu masuk.',
            ],
            [
                'id_jadwal' => 5, // Ahmad - Pemeriksaan AC
                'waktu_lapor' => $now->copy()->setTime(9, 30, 0),
                'lintang_lapor' => -6.20890100,
                'bujur_lapor' => 106.84580100,
                'lokasi_file_foto' => 'laporan/ac_meeting201_20240101_0930.jpg',
                'status_kondisi' => 'Ada Kendala',
                'catatan' => 'AC di ruang meeting 201 kurang dingin. Filter perlu diganti dan freon perlu diisi ulang.',
            ],
            [
                'id_jadwal' => 7, // Maya - Pemeriksaan Plumbing
                'waktu_lapor' => $now->copy()->setTime(10, 30, 0),
                'lintang_lapor' => -6.20895050,
                'bujur_lapor' => 106.84585050,
                'lokasi_file_foto' => 'laporan/plumbing_pantry_20240101_1030.jpg',
                'status_kondisi' => 'Ada Kendala',
                'catatan' => 'Ditemukan kebocoran kecil pada pipa wastafel. Perlu perbaikan segera.',
            ],
            [
                'id_jadwal' => 8, // Dewi - Patroli Keamanan Pagi
                'waktu_lapor' => $now->copy()->setTime(6, 50, 0),
                'lintang_lapor' => -6.20876600,
                'bujur_lapor' => 106.84567900,
                'lokasi_file_foto' => 'laporan/patroli_pagi_20240101_0650.jpg',
                'status_kondisi' => 'Aman/Bersih',
                'catatan' => 'Patroli pagi berjalan lancar. Semua area aman, tidak ada aktivitas mencurigakan.',
            ],
            [
                'id_jadwal' => 9, // Dewi - Pemeriksaan Area Parkir
                'waktu_lapor' => $now->copy()->setTime(8, 15, 0),
                'lintang_lapor' => -6.20920100,
                'bujur_lapor' => 106.84610100,
                'lokasi_file_foto' => 'laporan/parkir_zona_a_20240101_0815.jpg',
                'status_kondisi' => 'Aman/Bersih',
                'catatan' => 'Area parkir zona A dalam kondisi baik. Marka jalan masih jelas.',
            ],
            [
                'id_jadwal' => 11, // Budi - Patroli Rutin Area
                'waktu_lapor' => $now->copy()->setTime(11, 45, 0),
                'lintang_lapor' => -6.20876700,
                'bujur_lapor' => 106.84568000,
                'lokasi_file_foto' => 'laporan/patroli_rutin_20240101_1145.jpg',
                'status_kondisi' => 'Aman/Bersih',
                'catatan' => 'Patroli rutin selesai. Semua area dalam kondisi normal dan terkendali.',
            ],
        ];

        DB::table('laporan')->insert($laporan);
    }
}
