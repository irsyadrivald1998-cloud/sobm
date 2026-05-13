<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\LoginRequest;
use App\Models\Pengguna;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    /**
     * Login pengguna menggunakan NIK dan kata sandi.
     *
     * @param LoginRequest $request
     * @return JsonResponse
     */
    public function login(LoginRequest $request): JsonResponse
    {
        // Cari pengguna berdasarkan NIK
        $pengguna = Pengguna::where('nik', $request->nik)->first();

        // Validasi pengguna dan kata sandi
        if (!$pengguna || !Hash::check($request->kata_sandi, $pengguna->kata_sandi)) {
            return response()->json([
                'success' => false,
                'message' => 'NIK atau kata sandi salah',
            ], 401);
        }

        // Buat token untuk pengguna
        $token = $pengguna->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => [
                'pengguna' => [
                    'id' => $pengguna->id,
                    'nik' => $pengguna->nik,
                    'nama' => $pengguna->nama,
                    'peran' => $pengguna->peran,
                ],
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 200);
    }

    /**
     * Logout pengguna (revoke token).
     *
     * @return JsonResponse
     */
    public function logout(): JsonResponse
    {
        // Hapus token yang sedang digunakan
        auth()->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil',
        ], 200);
    }

    /**
     * Mendapatkan informasi pengguna yang sedang login.
     *
     * @return JsonResponse
     */
    public function me(): JsonResponse
    {
        $pengguna = auth()->user();

        return response()->json([
            'success' => true,
            'message' => 'Data pengguna berhasil diambil',
            'data' => [
                'id' => $pengguna->id,
                'nik' => $pengguna->nik,
                'nama' => $pengguna->nama,
                'peran' => $pengguna->peran,
                'dibuat_pada' => $pengguna->dibuat_pada,
                'diperbarui_pada' => $pengguna->diperbarui_pada,
            ],
        ], 200);
    }
}
