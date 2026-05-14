<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class PenggunaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $pengguna = [
            [
                'nik' => '123456',
                'nama' => 'Irsyad',
                'kata_sandi' => Hash::make('123456'),
                'peran' => 'admin',
            ],
            [
                'nik' => '234567',
                'nama' => 'Budi Santoso',
                'kata_sandi' => Hash::make('password123'),
                'peran' => 'pemantau',
            ],
            [
                'nik' => '345678',
                'nama' => 'Siti Nurhaliza',
                'kata_sandi' => Hash::make('password123'),
                'peran' => 'kebersihan',
            ],
            [
                'nik' => '456789',
                'nama' => 'Ahmad Dahlan',
                'kata_sandi' => Hash::make('password123'),
                'peran' => 'teknisi',
            ],
            [
                'nik' => '567890',
                'nama' => 'Dewi Lestari',
                'kata_sandi' => Hash::make('password123'),
                'peran' => 'keamanan',
            ],
            [
                'nik' => '678901',
                'nama' => 'Rudi Hartono',
                'kata_sandi' => Hash::make('password123'),
                'peran' => 'kebersihan',
            ],
            [
                'nik' => '789012',
                'nama' => 'Maya Sari',
                'kata_sandi' => Hash::make('password123'),
                'peran' => 'teknisi',
            ],
        ];

        DB::table('pengguna')->insert($pengguna);
    }
}
