<?php

namespace Database\Factories;

use App\Models\Report;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Report>
 */
class ReportFactory extends Factory
{
    protected $model = Report::class;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'check_in_time' => $this->faker->dateTime,
            'check_in_latitude' => $this->faker->latitude,
            'check_in_longitude' => $this->faker->longitude,
            'photo_path' => 'photos/test.jpg',
            'condition_status' => 'Aman/Bersih',
            'work_description' => $this->faker->sentence,
        ];
    }
}