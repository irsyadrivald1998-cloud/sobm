<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Area;
use App\Models\Checkpoint;
use App\Models\TaskCategory;
use App\Models\Schedule;
use App\Models\Report;
use App\Models\Issue;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use RuntimeException;
use Carbon\Carbon;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $password = env('SEEDER_DEFAULT_PASSWORD');

        if (blank($password)) {
            throw new RuntimeException(
                'SEEDER_DEFAULT_PASSWORD must be set before running the database seeder.'
            );
        }

        $hashedPassword = Hash::make($password);

        // 1. Seed Users
        $admin = User::updateOrCreate(
            ['employee_id' => 'admin_001'],
            [
                'name' => 'Super Admin',
                'password' => $hashedPassword,
                'role' => 'admin',
            ]
        );

        $viewer = User::updateOrCreate(
            ['employee_id' => 'viewer_001'],
            [
                'name' => 'Viewer Operasional',
                'password' => $hashedPassword,
                'role' => 'viewer',
            ]
        );

        $hk1 = User::updateOrCreate(
            ['employee_id' => 'hk_001'],
            [
                'name' => 'Budi Housekeeping',
                'password' => $hashedPassword,
                'role' => 'housekeeping',
            ]
        );

        $hk2 = User::updateOrCreate(
            ['employee_id' => 'hk_002'],
            [
                'name' => 'Siti Housekeeping',
                'password' => $hashedPassword,
                'role' => 'housekeeping',
            ]
        );

        $tk1 = User::updateOrCreate(
            ['employee_id' => 'tk_001'],
            [
                'name' => 'Joko Teknisi',
                'password' => $hashedPassword,
                'role' => 'teknisi',
            ]
        );

        $tk2 = User::updateOrCreate(
            ['employee_id' => 'tk_002'],
            [
                'name' => 'Andi Teknisi',
                'password' => $hashedPassword,
                'role' => 'teknisi',
            ]
        );

        $sec1 = User::updateOrCreate(
            ['employee_id' => 'sec_001'],
            [
                'name' => 'Agus Security',
                'password' => $hashedPassword,
                'role' => 'security',
            ]
        );

        $sec2 = User::updateOrCreate(
            ['employee_id' => 'sec_002'],
            [
                'name' => 'Rudi Security',
                'password' => $hashedPassword,
                'role' => 'security',
            ]
        );

        // 2. Seed Areas
        $area1 = Area::updateOrCreate(
            ['name' => 'Gedung Utama Universitas Jayanusa'],
            ['description' => 'Gedung utama untuk perkantoran dan ruang kuliah']
        );

        $area2 = Area::updateOrCreate(
            ['name' => 'Area Parkir & Lingkungan'],
            ['description' => 'Area luar ruangan, gerbang, dan tempat parkir']
        );

        // 3. Seed Checkpoints
        $cpLobby = Checkpoint::updateOrCreate(
            [
                'area_id' => $area1->id,
                'name' => 'Lobby Gedung Utama',
            ],
            [
                'latitude' => -0.94326885,
                'longitude' => 100.35396392,
                'radius_meter' => 100,
            ]
        );

        $cpLab = Checkpoint::updateOrCreate(
            [
                'area_id' => $area1->id,
                'name' => 'Laboratorium Komputer Lantai 2',
            ],
            [
                'latitude' => -0.94331000,
                'longitude' => 100.35412000,
                'radius_meter' => 50,
            ]
        );

        $cpGate = Checkpoint::updateOrCreate(
            [
                'area_id' => $area2->id,
                'name' => 'Pos Satpam & Gerbang Depan',
            ],
            [
                'latitude' => -0.94311000,
                'longitude' => 100.35381000,
                'radius_meter' => 80,
            ]
        );

        // 4. Seed Task Categories
        $taskHk1 = TaskCategory::updateOrCreate(
            [
                'target_role' => 'housekeeping',
                'task_name' => 'Sapu dan Pel Lantai',
            ]
        );

        $taskHk2 = TaskCategory::updateOrCreate(
            [
                'target_role' => 'housekeeping',
                'task_name' => 'Bersihkan Kaca Jendela Lobby',
            ]
        );

        $taskTk1 = TaskCategory::updateOrCreate(
            [
                'target_role' => 'teknisi',
                'task_name' => 'Cek Kelayakan AC & Listrik',
            ]
        );

        $taskSec1 = TaskCategory::updateOrCreate(
            [
                'target_role' => 'security',
                'task_name' => 'Patroli Keamanan & Cek Pagar',
            ]
        );

        // 5. Seed Schedules, Reports, and Issues
        $today = Carbon::today()->format('Y-m-d');
        $yesterday = Carbon::yesterday()->format('Y-m-d');
        $tomorrow = Carbon::tomorrow()->format('Y-m-d');

        // Yesterday: Housekeeping (Completed, Clean)
        $schYesterdayHk = Schedule::updateOrCreate(
            [
                'user_id' => $hk1->id,
                'checkpoint_id' => $cpLobby->id,
                'task_category_id' => $taskHk1->id,
                'shift_date' => $yesterday,
                'scheduled_time' => '08:00:00',
            ],
            ['status' => 'completed']
        );

        $repYesterdayHk = Report::updateOrCreate(
            ['schedule_id' => $schYesterdayHk->id],
            [
                'check_in_time' => Carbon::yesterday()->setTime(8, 5, 0),
                'check_in_latitude' => -0.94326885,
                'check_in_longitude' => 100.35396392,
                'photo_path' => 'reports/sample_hk.jpg',
                'condition_status' => 'Aman/Bersih',
                'notes' => 'Lantai lobby sudah bersih disapu dan dipel.',
            ]
        );

        // Yesterday: Teknisi (Completed, Issue Found, Resolved by Admin)
        $schYesterdayTk = Schedule::updateOrCreate(
            [
                'user_id' => $tk1->id,
                'checkpoint_id' => $cpLab->id,
                'task_category_id' => $taskTk1->id,
                'shift_date' => $yesterday,
                'scheduled_time' => '10:00:00',
            ],
            ['status' => 'completed']
        );

        $repYesterdayTk = Report::updateOrCreate(
            ['schedule_id' => $schYesterdayTk->id],
            [
                'check_in_time' => Carbon::yesterday()->setTime(10, 15, 0),
                'check_in_latitude' => -0.94331000,
                'check_in_longitude' => 100.35412000,
                'photo_path' => 'reports/sample_tk.jpg',
                'condition_status' => 'Ada Kendala',
                'notes' => 'AC berisik dan bocor air.',
            ]
        );

        $issueYesterdayTk = Issue::updateOrCreate(
            ['report_id' => $repYesterdayTk->id],
            [
                'issue_description' => 'AC split di Lab 2 bocor air dan suaranya bising.',
                'is_resolved' => true,
                'resolved_at' => Carbon::yesterday()->setTime(14, 0, 0),
                'resolved_by' => $admin->id,
                'resolution_notes' => 'Freon AC ditambah dan selang pembuangan air sudah dibersihkan/diganti.',
            ]
        );

        // Today: Security (Completed, Issue Found, Unresolved)
        $schTodaySec = Schedule::updateOrCreate(
            [
                'user_id' => $sec1->id,
                'checkpoint_id' => $cpGate->id,
                'task_category_id' => $taskSec1->id,
                'shift_date' => $today,
                'scheduled_time' => '22:00:00',
            ],
            ['status' => 'completed']
        );

        $repTodaySec = Report::updateOrCreate(
            ['schedule_id' => $schTodaySec->id],
            [
                'check_in_time' => Carbon::today()->setTime(22, 10, 0),
                'check_in_latitude' => -0.94311000,
                'check_in_longitude' => 100.35381000,
                'photo_path' => 'reports/sample_sec.jpg',
                'condition_status' => 'Ada Kendala',
                'notes' => 'Lampu sorot gerbang utama mati.',
            ]
        );

        $issueTodaySec = Issue::updateOrCreate(
            ['report_id' => $repTodaySec->id],
            [
                'issue_description' => 'Lampu sorot LED di gerbang masuk utama mati total, area depan menjadi sangat gelap.',
                'is_resolved' => false,
            ]
        );

        // Today: Housekeeping (Pending)
        Schedule::updateOrCreate(
            [
                'user_id' => $hk2->id,
                'checkpoint_id' => $cpLobby->id,
                'task_category_id' => $taskHk2->id,
                'shift_date' => $today,
                'scheduled_time' => '14:00:00',
            ],
            ['status' => 'pending']
        );

        // Tomorrow: Housekeeping (Pending)
        Schedule::updateOrCreate(
            [
                'user_id' => $hk1->id,
                'checkpoint_id' => $cpLobby->id,
                'task_category_id' => $taskHk1->id,
                'shift_date' => $tomorrow,
                'scheduled_time' => '08:00:00',
            ],
            ['status' => 'pending']
        );

        // Tomorrow: Teknisi (Pending)
        Schedule::updateOrCreate(
            [
                'user_id' => $tk2->id,
                'checkpoint_id' => $cpLab->id,
                'task_category_id' => $taskTk1->id,
                'shift_date' => $tomorrow,
                'scheduled_time' => '09:00:00',
            ],
            ['status' => 'pending']
        );
    }
}
