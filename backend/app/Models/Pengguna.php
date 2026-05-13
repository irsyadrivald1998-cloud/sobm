<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Pengguna extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens;

    /**
     * Nama tabel yang digunakan oleh model ini.
     *
     * @var string
     */
    protected $table = 'pengguna';

    /**
     * Nama kolom primary key.
     *
     * @var string
     */
    protected $primaryKey = 'id';

    /**
     * Menonaktifkan timestamps bawaan Laravel (created_at, updated_at).
     * Karena kita menggunakan dibuat_pada dan diperbarui_pada.
     *
     * @var bool
     */
    public $timestamps = false;

    /**
     * Nama kolom untuk created_at custom.
     *
     * @var string
     */
    const CREATED_AT = 'dibuat_pada';

    /**
     * Nama kolom untuk updated_at custom.
     *
     * @var string
     */
    const UPDATED_AT = 'diperbarui_pada';

    /**
     * Atribut yang dapat diisi secara massal.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'nik',
        'nama',
        'kata_sandi',
        'peran',
    ];

    /**
     * Atribut yang harus disembunyikan untuk serialisasi.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'kata_sandi',
        'remember_token',
    ];

    /**
     * Mendapatkan nama kolom password untuk autentikasi.
     *
     * @return string
     */
    public function getAuthPassword()
    {
        return $this->kata_sandi;
    }

    /**
     * Mendapatkan nama kolom username untuk autentikasi.
     * Menggunakan NIK sebagai username.
     *
     * @return string
     */
    public function getAuthIdentifierName()
    {
        return 'nik';
    }

    /**
     * Cast atribut ke tipe data native.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'dibuat_pada' => 'datetime',
            'diperbarui_pada' => 'datetime',
        ];
    }

    /**
     * Relasi ke tabel jadwal.
     */
    public function jadwal()
    {
        return $this->hasMany(Jadwal::class, 'id_pengguna');
    }

    /**
     * Scope untuk filter berdasarkan peran.
     */
    public function scopeByPeran($query, $peran)
    {
        return $query->where('peran', $peran);
    }
}
