<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class AreaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $areas = [
            [
                'nama_area' => 'Gedung A - Lantai 1',
                'deskripsi' => 'Area lobby utama dan ruang tunggu gedung A',
            ],
            [
                'nama_area' => 'Gedung A - Lantai 2',
                'deskripsi' => 'Area kantor dan ruang meeting gedung A lantai 2',
            ],
            [
                'nama_area' => 'Gedung B - Lantai 1',
                'deskripsi' => 'Area parkir dan gudang gedung B',
            ],
            [
                'nama_area' => 'Taman Depan',
                'deskripsi' => 'Area taman dan landscape bagian depan kompleks',
            ],
            [
                'nama_area' => 'Area Parkir Utama',
                'deskripsi' => 'Area parkir kendaraan karyawan dan tamu',
            ],
        ];

        DB::table('area')->insert($areas);
    }
}
