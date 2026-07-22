# Entity Relationship Diagram (ERD)

Dokumen ini dibuat berdasarkan migration, Eloquent model, controller, dan
resource Filament yang ada di `backend`.

## ERD domain

```mermaid
erDiagram
    USERS ||--o{ SCHEDULES : "mendapat tugas"
    AREAS ||--o{ CHECKPOINTS : "memiliki"
    CHECKPOINTS ||--o{ SCHEDULES : "menjadi lokasi"
    TASK_CATEGORIES ||--o{ SCHEDULES : "mengklasifikasikan"
    SCHEDULES ||--o| REPORTS : "dilaporkan"
    REPORTS ||--o| ISSUES : "dapat memiliki kendala"

    USERS {
        bigint id PK
        varchar employee_id UK
        varchar name
        varchar password
        enum role
        varchar remember_token
        timestamp created_at
        timestamp updated_at
    }

    AREAS {
        bigint id PK
        varchar name
        text description "nullable"
        timestamp created_at
        timestamp updated_at
    }

    CHECKPOINTS {
        bigint id PK
        bigint area_id FK
        varchar name
        decimal latitude
        decimal longitude
        int radius_meter
        timestamp created_at
        timestamp updated_at
    }

    TASK_CATEGORIES {
        bigint id PK
        enum target_role
        varchar task_name
        timestamp created_at
        timestamp updated_at
    }

    SCHEDULES {
        bigint id PK
        bigint user_id FK
        bigint checkpoint_id FK
        bigint task_category_id FK
        date shift_date
        time scheduled_time
        enum status
        timestamp created_at
        timestamp updated_at
    }

    REPORTS {
        bigint id PK
        bigint schedule_id FK UK
        timestamp check_in_time
        decimal check_in_latitude
        decimal check_in_longitude
        varchar photo_path
        enum condition_status
        text notes "nullable"
        timestamp created_at
        timestamp updated_at
    }

    ISSUES {
        bigint id PK
        bigint report_id FK
        text issue_description
        boolean is_resolved
        timestamp created_at
        timestamp updated_at
    }
```

## Relasi dan aturan bisnis yang terlihat

| Relasi | Kardinalitas | Implementasi |
| --- | --- | --- |
| `users` - `schedules` | 1:N | `schedules.user_id`, cascade delete |
| `areas` - `checkpoints` | 1:N | `checkpoints.area_id`, cascade delete |
| `checkpoints` - `schedules` | 1:N | `schedules.checkpoint_id`, cascade delete |
| `task_categories` - `schedules` | 1:N | `schedules.task_category_id`, cascade delete |
| `schedules` - `reports` | 1:0..1 | FK dan unique index pada `reports.schedule_id` |
| `reports` - `issues` | 1:0..1 secara model | `Report::issue()` memakai `hasOne`, tetapi database belum memberi unique constraint pada `issues.report_id` |

`reports` dibuat melalui `POST /api/reports`. Endpoint tersebut memeriksa
kepemilikan jadwal, tanggal jadwal, dan jarak check-in terhadap checkpoint.
Jika kondisi `Ada Kendala`, satu issue dibuat untuk report tersebut.

## Tabel pendukung framework

Tabel berikut bukan bagian dari domain operasional, tetapi dibuat/digunakan
oleh Laravel:

- `sessions`: penyimpanan session Filament; `user_id` hanya indexed dan tidak
  memiliki foreign key pada migration.
- `cache` dan `cache_locks`: penyimpanan cache/database lock.
- `jobs`: antrean pekerjaan.

Sanctum juga membutuhkan `personal_access_tokens` karena `User` memakai
`HasApiTokens`. Namun migration untuk tabel tersebut tidak ditemukan di
repository ini, sehingga tabel itu perlu dipastikan tersedia pada database
deployment baru.

## Batasan ERD

ERD ini menggambarkan schema yang didefinisikan oleh migration di repository,
bukan seluruh tabel yang mungkin sudah ada pada database server. Tabel token
Sanctum, misalnya, disebut sebagai dependensi runtime tetapi tidak dapat
dianggap sebagai bagian schema yang versioned sampai migration-nya ditambahkan
ke repository.
