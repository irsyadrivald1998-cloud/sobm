<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function update(Request $request)
    {
        $user = $request->user();

        // 1. Jika request adalah upload avatar
        if ($request->hasFile('avatar')) {
            $request->validate([
                'avatar' => 'required|image|mimes:jpeg,jpg,png,webp|max:2048',
            ]);

            // Hapus foto lama jika ada
            if ($user->photo_path) {
                Storage::disk('public')->delete($user->photo_path);
            }

            // Simpan foto baru
            $path = $request->file('avatar')->store('avatars', 'public');
            $user->photo_path = $path;
            $user->save();

            return ApiResponse::success([
                'user' => $user->fresh()
            ], 'Foto profil berhasil diperbarui.');
        }

        // 2. Jika request adalah update data profil (name, email, phone)
        $request->validate([
            'name' => 'required|string|min:3|max:100',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'phone' => 'nullable|string|min:10|max:15',
        ]);

        $user->update($request->only('name', 'email', 'phone'));

        return ApiResponse::success([
            'user' => $user->fresh()
        ], 'Profil berhasil diperbarui.');
    }
}
