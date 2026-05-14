<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            PenggunaSeeder::class,
            AreaSeeder::class,
            TitikKontrolSeeder::class,
            KategoriTugasSeeder::class,
            JadwalSeeder::class,
            LaporanSeeder::class,
            TemuanMasalahSeeder::class,
        ]);
    }
}
