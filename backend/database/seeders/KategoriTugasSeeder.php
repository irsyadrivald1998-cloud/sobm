<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class KategoriTugasSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $kategoriTugas = [
            // Tugas untuk Admin
            [
                'peran_target' => 'admin',
                'nama_tugas' => 'Inspeksi Umum Fasilitas',
            ],
            [
                'peran_target' => 'admin',
                'nama_tugas' => 'Audit Keseluruhan Area',
            ],
            // Tugas untuk Pemantau
            [
                'peran_target' => 'pemantau',
                'nama_tugas' => 'Monitoring CCTV',
            ],
            [
                'peran_target' => 'pemantau',
                'nama_tugas' => 'Patroli Rutin Area',
            ],
            // Tugas untuk Kebersihan
            [
                'peran_target' => 'kebersihan',
                'nama_tugas' => 'Pembersihan Toilet',
            ],
            [
                'peran_target' => 'kebersihan',
                'nama_tugas' => 'Pembersihan Lobby',
            ],
            [
                'peran_target' => 'kebersihan',
                'nama_tugas' => 'Pembersihan Ruang Meeting',
            ],
            [
                'peran_target' => 'kebersihan',
                'nama_tugas' => 'Perawatan Taman',
            ],
            // Tugas untuk Teknisi
            [
                'peran_target' => 'teknisi',
                'nama_tugas' => 'Pemeriksaan AC',
            ],
            [
                'peran_target' => 'teknisi',
                'nama_tugas' => 'Pemeriksaan Listrik',
            ],
            [
                'peran_target' => 'teknisi',
                'nama_tugas' => 'Pemeriksaan Plumbing',
            ],
            [
                'peran_target' => 'teknisi',
                'nama_tugas' => 'Maintenance Lift',
            ],
            // Tugas untuk Keamanan
            [
                'peran_target' => 'keamanan',
                'nama_tugas' => 'Patroli Keamanan Pagi',
            ],
            [
                'peran_target' => 'keamanan',
                'nama_tugas' => 'Patroli Keamanan Malam',
            ],
            [
                'peran_target' => 'keamanan',
                'nama_tugas' => 'Pemeriksaan Pintu Darurat',
            ],
            [
                'peran_target' => 'keamanan',
                'nama_tugas' => 'Pemeriksaan Area Parkir',
            ],
        ];

        DB::table('kategori_tugas')->insert($kategoriTugas);
    }
}
