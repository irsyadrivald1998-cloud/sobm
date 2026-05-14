<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class TitikKontrolSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $titikKontrol = [
            // Gedung A - Lantai 1
            [
                'id_area' => 1,
                'nama_titik' => 'Pintu Masuk Utama',
                'lintang' => -6.20876543,
                'bujur' => 106.84567890,
                'radius_meter' => 15,
            ],
            [
                'id_area' => 1,
                'nama_titik' => 'Lobby Resepsionis',
                'lintang' => -6.20880000,
                'bujur' => 106.84570000,
                'radius_meter' => 10,
            ],
            [
                'id_area' => 1,
                'nama_titik' => 'Toilet Lantai 1',
                'lintang' => -6.20885000,
                'bujur' => 106.84575000,
                'radius_meter' => 8,
            ],
            // Gedung A - Lantai 2
            [
                'id_area' => 2,
                'nama_titik' => 'Ruang Meeting 201',
                'lintang' => -6.20890000,
                'bujur' => 106.84580000,
                'radius_meter' => 10,
            ],
            [
                'id_area' => 2,
                'nama_titik' => 'Pantry Lantai 2',
                'lintang' => -6.20895000,
                'bujur' => 106.84585000,
                'radius_meter' => 8,
            ],
            // Gedung B - Lantai 1
            [
                'id_area' => 3,
                'nama_titik' => 'Pintu Parkir Basement',
                'lintang' => -6.20900000,
                'bujur' => 106.84590000,
                'radius_meter' => 20,
            ],
            [
                'id_area' => 3,
                'nama_titik' => 'Gudang Penyimpanan',
                'lintang' => -6.20905000,
                'bujur' => 106.84595000,
                'radius_meter' => 15,
            ],
            // Taman Depan
            [
                'id_area' => 4,
                'nama_titik' => 'Taman Area 1',
                'lintang' => -6.20910000,
                'bujur' => 106.84600000,
                'radius_meter' => 25,
            ],
            [
                'id_area' => 4,
                'nama_titik' => 'Taman Area 2',
                'lintang' => -6.20915000,
                'bujur' => 106.84605000,
                'radius_meter' => 25,
            ],
            // Area Parkir Utama
            [
                'id_area' => 5,
                'nama_titik' => 'Parkir Zona A',
                'lintang' => -6.20920000,
                'bujur' => 106.84610000,
                'radius_meter' => 30,
            ],
            [
                'id_area' => 5,
                'nama_titik' => 'Parkir Zona B',
                'lintang' => -6.20925000,
                'bujur' => 106.84615000,
                'radius_meter' => 30,
            ],
        ];

        DB::table('titik_kontrol')->insert($titikKontrol);
    }
}
