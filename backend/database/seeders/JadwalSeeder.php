<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class JadwalSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $now = Carbon::now();
        
        $jadwal = [
            // Jadwal untuk Siti Nurhaliza (Kebersihan) - id_pengguna: 3
            [
                'id_pengguna' => 3,
                'id_titik_kontrol' => 3, // Toilet Lantai 1
                'id_kategori_tugas' => 5, // Pembersihan Toilet
                'waktu_mulai' => $now->copy()->setTime(8, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(9, 0, 0),
                'status' => 'selesai',
            ],
            [
                'id_pengguna' => 3,
                'id_titik_kontrol' => 2, // Lobby Resepsionis
                'id_kategori_tugas' => 6, // Pembersihan Lobby
                'waktu_mulai' => $now->copy()->setTime(9, 30, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(10, 30, 0),
                'status' => 'selesai',
            ],
            // Jadwal untuk Rudi Hartono (Kebersihan) - id_pengguna: 6
            [
                'id_pengguna' => 6,
                'id_titik_kontrol' => 4, // Ruang Meeting 201
                'id_kategori_tugas' => 7, // Pembersihan Ruang Meeting
                'waktu_mulai' => $now->copy()->setTime(10, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(11, 0, 0),
                'status' => 'menunggu',
            ],
            [
                'id_pengguna' => 6,
                'id_titik_kontrol' => 8, // Taman Area 1
                'id_kategori_tugas' => 8, // Perawatan Taman
                'waktu_mulai' => $now->copy()->setTime(14, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(16, 0, 0),
                'status' => 'menunggu',
            ],
            // Jadwal untuk Ahmad Dahlan (Teknisi) - id_pengguna: 4
            [
                'id_pengguna' => 4,
                'id_titik_kontrol' => 4, // Ruang Meeting 201
                'id_kategori_tugas' => 9, // Pemeriksaan AC
                'waktu_mulai' => $now->copy()->setTime(8, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(10, 0, 0),
                'status' => 'selesai',
            ],
            [
                'id_pengguna' => 4,
                'id_titik_kontrol' => 7, // Gudang Penyimpanan
                'id_kategori_tugas' => 10, // Pemeriksaan Listrik
                'waktu_mulai' => $now->copy()->setTime(13, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(15, 0, 0),
                'status' => 'menunggu',
            ],
            // Jadwal untuk Maya Sari (Teknisi) - id_pengguna: 7
            [
                'id_pengguna' => 7,
                'id_titik_kontrol' => 5, // Pantry Lantai 2
                'id_kategori_tugas' => 11, // Pemeriksaan Plumbing
                'waktu_mulai' => $now->copy()->setTime(9, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(11, 0, 0),
                'status' => 'selesai',
            ],
            // Jadwal untuk Dewi Lestari (Keamanan) - id_pengguna: 5
            [
                'id_pengguna' => 5,
                'id_titik_kontrol' => 1, // Pintu Masuk Utama
                'id_kategori_tugas' => 13, // Patroli Keamanan Pagi
                'waktu_mulai' => $now->copy()->setTime(6, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(7, 0, 0),
                'status' => 'selesai',
            ],
            [
                'id_pengguna' => 5,
                'id_titik_kontrol' => 10, // Parkir Zona A
                'id_kategori_tugas' => 16, // Pemeriksaan Area Parkir
                'waktu_mulai' => $now->copy()->setTime(7, 30, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(8, 30, 0),
                'status' => 'selesai',
            ],
            [
                'id_pengguna' => 5,
                'id_titik_kontrol' => 6, // Pintu Parkir Basement
                'id_kategori_tugas' => 15, // Pemeriksaan Pintu Darurat
                'waktu_mulai' => $now->copy()->setTime(16, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(17, 0, 0),
                'status' => 'menunggu',
            ],
            // Jadwal untuk Budi Santoso (Pemantau) - id_pengguna: 2
            [
                'id_pengguna' => 2,
                'id_titik_kontrol' => 1, // Pintu Masuk Utama
                'id_kategori_tugas' => 4, // Patroli Rutin Area
                'waktu_mulai' => $now->copy()->setTime(10, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(12, 0, 0),
                'status' => 'selesai',
            ],
            [
                'id_pengguna' => 2,
                'id_titik_kontrol' => 11, // Parkir Zona B
                'id_kategori_tugas' => 4, // Patroli Rutin Area
                'waktu_mulai' => $now->copy()->setTime(14, 0, 0),
                'waktu_batas_selesai' => $now->copy()->setTime(16, 0, 0),
                'status' => 'menunggu',
            ],
        ];

        DB::table('jadwal')->insert($jadwal);
    }
}
