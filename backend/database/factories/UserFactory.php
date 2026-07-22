<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    public function definition(): array
    {
        return [
            'employee_id' => 'emp_' . fake()->unique()->numerify('#####'),
            'name' => fake()->name(),
            'password' => static::$password ??= Hash::make('password'),
            'role' => 'housekeeping',
            'remember_token' => Str::random(10),
        ];
    }
}
