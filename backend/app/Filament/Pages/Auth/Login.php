<?php

namespace App\Filament\Pages\Auth;

use Filament\Auth\Pages\Login as BaseLogin;
use Filament\Schemas\Components\Component;
use Filament\Schemas\Schema;
use Filament\Forms\Components\TextInput;
use Illuminate\Validation\ValidationException;

class Login extends BaseLogin
{
    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                $this->getEmployeeIdFormComponent(),
                $this->getPasswordFormComponent(),
                $this->getRememberFormComponent(),
            ]);
    }

    protected function getEmployeeIdFormComponent(): Component
    {
        return TextInput::make('employee_id')
            ->label('Employee ID')
            ->required()
            ->autocomplete()
            ->autofocus()
            ->extraInputAttributes(['tabindex' => 1]);
    }

    protected function getCredentialsFromFormData(array $data): array
    {
        $credentials = [
            'employee_id' => $data['employee_id'] ?? null,
            'password' => $data['password'] ?? null,
        ];

        return array_filter($credentials, fn($value) => filled($value));
    }

    protected function throwFailureValidationException(): never
    {
        throw ValidationException::withMessages([
            'data.employee_id' => 'Employee ID atau password salah.',
        ]);
    }
}
