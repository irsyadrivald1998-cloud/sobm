<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreReportRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();

        if (! $user) {
            return false;
        }

        return in_array($user->role, ['housekeeping', 'teknisi', 'security'], true);
    }

    /**
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'schedule_id' => 'required|integer|exists:schedules,id',
            'check_in_latitude' => 'required|numeric|between:-90,90',
            'check_in_longitude' => 'required|numeric|between:-180,180',
            'photo' => 'required|image|mimes:jpeg,jpg,png,webp|max:2048',
            'condition_status' => 'required|in:Aman/Bersih,Ada Kendala',
            'notes' => 'nullable|string',
            'issue_description' => 'required_if:condition_status,Ada Kendala|string',
        ];
    }

    public function messages(): array
    {
        return [
            'schedule_id.required' => 'Jadwal wajib dipilih.',
            'check_in_latitude.required' => 'Latitude check-in wajib diisi.',
            'check_in_longitude.required' => 'Longitude check-in wajib diisi.',
            'photo.required' => 'Foto wajib diunggah.',
            'photo.image' => 'Berkas harus berupa gambar.',
            'photo.max' => 'Ukuran foto maksimal 2 MB.',
        ];
    }
}
