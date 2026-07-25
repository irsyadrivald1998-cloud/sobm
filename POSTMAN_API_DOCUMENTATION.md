# SOBM API Documentation - Postman Collection

## Base URL
```
http://localhost:8000/api
```

## Authentication
All endpoints except `/login` require authentication via Bearer Token (Laravel Sanctum).

### Headers
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

---

## 1. Authentication

### 1.1 Login
**Endpoint:** `POST /api/login`

**Description:** Authenticate user and get access token.

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "employee_id": "EMP001",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "user": {
      "id": 1,
      "employee_id": "EMP001",
      "name": "John Doe",
      "role": "housekeeping",
      "created_at": "2026-07-24T00:00:00.000000Z",
      "updated_at": "2026-07-24T00:00:00.000000Z"
    },
    "token": "1|abc123xyz456..."
  }
}
```

**Error Response (422):**
```json
{
  "message": "Kredensial tidak valid.",
  "errors": {
    "employee_id": ["Kredensial tidak valid."]
  }
}
```

**Rate Limiting:** 5 attempts per 5 minutes per IP.

---

### 1.2 Logout
**Endpoint:** `POST /api/logout`

**Description:** Revoke current access token.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Berhasil keluar.",
  "data": null
}
```

---

### 1.3 Get Current User
**Endpoint:** `GET /api/user`

**Description:** Get authenticated user information.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "id": 1,
    "employee_id": "EMP001",
    "name": "John Doe",
    "role": "housekeeping",
    "created_at": "2026-07-24T00:00:00.000000Z",
    "updated_at": "2026-07-24T00:00:00.000000Z"
  }
}
```

---

## 2. Schedules

### 2.1 Get User Schedules
**Endpoint:** `GET /api/schedules`

**Description:** Get all schedules for authenticated user.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters:** None

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "schedules": [
      {
        "id": 1,
        "user_id": 1,
        "checkpoint_id": 1,
        "task_category_id": 1,
        "shift_date": "2026-07-25",
        "scheduled_time": "08:00:00",
        "status": "pending",
        "created_at": "2026-07-24T00:00:00.000000Z",
        "updated_at": "2026-07-24T00:00:00.000000Z",
        "checkpoint": {
          "id": 1,
          "area_id": 1,
          "name": "Lobby Utama",
          "latitude": -0.94326885,
          "longitude": 100.35396392,
          "radius_meter": 50,
          "created_at": "2026-07-24T00:00:00.000000Z",
          "updated_at": "2026-07-24T00:00:00.000000Z"
        },
        "taskCategory": {
          "id": 1,
          "target_role": "housekeeping",
          "task_name": "Pembersihan Lobby",
          "created_at": "2026-07-24T00:00:00.000000Z",
          "updated_at": "2026-07-24T00:00:00.000000Z"
        }
      }
    ]
  }
}
```

**Access:** Worker roles only (housekeeping, teknisi, security)

---

## 3. Reports

### 3.1 Create Report
**Endpoint:** `POST /api/reports`

**Description:** Submit a task report with photo and location.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body (form-data):**
```
schedule_id: 1 (optional, nullable)
check_in_latitude: -0.94326885 (required, numeric, between -90 and 90)
check_in_longitude: 100.35396392 (required, numeric, between -180 and 180)
photo: [file] (required, image, max 2MB, jpeg/jpg/png/webp)
condition_status: "Aman/Bersih" or "Ada Kendala" (required)
work_description: "Pembersihan selesai" (required, string)
notes: "Catatan tambahan" (optional, nullable)
issue_description: "Ada kerusakan AC" (required if condition_status is "Ada Kendala")
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Laporan berhasil dikirim.",
  "data": {
    "id": 1,
    "schedule_id": 1,
    "check_in_time": "2026-07-24T10:30:00.000000Z",
    "check_in_latitude": "-0.94326885",
    "check_in_longitude": "100.35396392",
    "photo_path": "reports/abc123.jpg",
    "condition_status": "Aman/Bersih",
    "work_description": "Pembersihan selesai",
    "notes": "Catatan tambahan",
    "created_at": "2026-07-24T10:30:00.000000Z",
    "updated_at": "2026-07-24T10:30:00.000000Z",
    "issue": null
  }
}
```

**Validation Rules:**
- Geofence validation: User must be within checkpoint radius (if schedule_id provided)
- Schedule validation: User can only report their own schedules
- Date validation: Report can only be submitted on the scheduled date
- Duplicate prevention: Only one report per schedule

**Access:** Worker roles only

---

### 3.2 Get Reports
**Endpoint:** `GET /api/reports`

**Description:** Get reports with filtering options.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters:**
```
role: "housekeeping" (optional, filter by user role)
date: "2026-07-24" (optional, filter by date)
checkpoint_id: 1 (optional, filter by checkpoint)
condition_status: "Aman/Bersih" (optional, filter by condition)
since: "2026-07-24T10:00:00" (optional, for polling - get reports after timestamp)
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Aktivitas laporan berhasil diambil.",
  "data": {
    "reports": {
      "current_page": 1,
      "data": [
        {
          "id": 1,
          "schedule_id": 1,
          "check_in_time": "2026-07-24T10:30:00.000000Z",
          "check_in_latitude": "-0.94326885",
          "check_in_longitude": "100.35396392",
          "photo_path": "reports/abc123.jpg",
          "condition_status": "Aman/Bersih",
          "work_description": "Pembersihan selesai",
          "notes": null,
          "created_at": "2026-07-24T10:30:00.000000Z",
          "updated_at": "2026-07-24T10:30:00.000000Z",
          "schedule": {
            "id": 1,
            "user_id": 1,
            "checkpoint": {
              "id": 1,
              "name": "Lobby Utama"
            },
            "taskCategory": {
              "id": 1,
              "task_name": "Pembersihan Lobby"
            },
            "user": {
              "id": 1,
              "name": "John Doe",
              "role": "housekeeping"
            }
          },
          "issue": null
        }
      ],
      "per_page": 20,
      "total": 1
    }
  }
}
```

**Access:** All authenticated users

---

## 4. Attendance

### 4.1 Get Today's Attendance
**Endpoint:** `GET /api/attendance/today`

**Description:** Get attendance status for today.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response (200 OK - No attendance yet):**
```json
{
  "success": true,
  "message": "Belum absen hari ini.",
  "data": null
}
```

**Response (200 OK - Has attendance):**
```json
{
  "success": true,
  "message": "Status absen hari ini.",
  "data": {
    "id": 1,
    "user_id": 1,
    "date": "2026-07-24",
    "clock_in_time": "08:10:00",
    "clock_out_time": "17:00:00",
    "clock_in_latitude": "-0.94326885",
    "clock_in_longitude": "100.35396392",
    "clock_out_latitude": "-0.94326885",
    "clock_out_longitude": "100.35396392",
    "clock_in_photo_path": "attendances/clock_in/abc123.jpg",
    "clock_out_photo_path": "attendances/clock_out/def456.jpg",
    "status": "Terlambat",
    "notes": null,
    "created_at": "2026-07-24T08:10:00.000000Z",
    "updated_at": "2026-07-24T17:00:00.000000Z"
  }
}
```

**Access:** Worker roles only

---

### 4.2 Clock In
**Endpoint:** `POST /api/attendance/clock-in`

**Description:** Clock in for attendance.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body (form-data):**
```
latitude: -0.94326885 (required, numeric, between -90 and 90)
longitude: 100.35396392 (required, numeric, between -180 and 180)
photo: [file] (required, image, max 2MB, jpeg/jpg/png/webp)
notes: "Terlambat karena macet" (optional, nullable)
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Absen masuk berhasil dilakukan.",
  "data": {
    "id": 1,
    "user_id": 1,
    "date": "2026-07-24",
    "clock_in_time": "08:10:00",
    "clock_out_time": null,
    "clock_in_latitude": "-0.94326885",
    "clock_in_longitude": "100.35396392",
    "clock_out_latitude": null,
    "clock_out_longitude": null,
    "clock_in_photo_path": "attendances/clock_in/abc123.jpg",
    "clock_out_photo_path": null,
    "status": "Terlambat",
    "notes": "Terlambat karena macet",
    "created_at": "2026-07-24T08:10:00.000000Z",
    "updated_at": "2026-07-24T08:10:00.000000Z"
  }
}
```

**Validation Rules:**
- Geofence validation: User must be within 100 meters of office (-0.94326885, 100.35396392)
- Time validation: After 08:15:00 = "Terlambat", before = "Hadir"
- Duplicate prevention: Only one clock-in per day

**Office Location:**
- Latitude: -0.94326885
- Longitude: 100.35396392
- Max Radius: 100 meters

**Access:** Worker roles only

---

### 4.3 Clock Out
**Endpoint:** `POST /api/attendance/clock-out`

**Description:** Clock out for attendance.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body (form-data):**
```
latitude: -0.94326885 (required, numeric, between -90 and 90)
longitude: 100.35396392 (required, numeric, between -180 and 180)
photo: [file] (required, image, max 2MB, jpeg/jpg/png/webp)
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Absen keluar berhasil dilakukan.",
  "data": {
    "id": 1,
    "user_id": 1,
    "date": "2026-07-24",
    "clock_in_time": "08:10:00",
    "clock_out_time": "17:00:00",
    "clock_in_latitude": "-0.94326885",
    "clock_in_longitude": "100.35396392",
    "clock_out_latitude": "-0.94326885",
    "clock_out_longitude": "100.35396392",
    "clock_in_photo_path": "attendances/clock_in/abc123.jpg",
    "clock_out_photo_path": "attendances/clock_out/def456.jpg",
    "status": "Terlambat",
    "notes": null,
    "created_at": "2026-07-24T08:10:00.000000Z",
    "updated_at": "2026-07-24T17:00:00.000000Z"
  }
}
```

**Validation Rules:**
- Must have clocked in first
- Geofence validation: User must be within 100 meters of office
- Duplicate prevention: Only one clock-out per day

**Access:** Worker roles only

---

## 5. Issues

### 5.1 Update Issue Status
**Endpoint:** `PATCH /api/issues/{issue}/status`

**Description:** Update issue status and resolution notes.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**URL Parameters:**
```
issue: 1 (issue ID)
```

**Request Body:**
```json
{
  "status": "resolved",
  "resolution_notes": "AC sudah diperbaiki oleh teknisi"
}
```

**Status Options:**
- `open` - Issue baru
- `in-progress` - Sedang dikerjakan
- `resolved` - Sudah selesai

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Status issue berhasil diupdate.",
  "data": {
    "id": 1,
    "report_id": 1,
    "issue_description": "Ada kerusakan AC",
    "is_resolved": true,
    "status": "resolved",
    "resolution_notes": "AC sudah diperbaiki oleh teknisi",
    "resolved_by": 1,
    "created_at": "2026-07-24T10:30:00.000000Z",
    "updated_at": "2026-07-24T14:00:00.000000Z"
  }
}
```

**Validation Rules:**
- `resolution_notes` is required when status is `resolved`

**Access:** Worker roles only

---

## 6. Leave Submissions

### 6.1 Create Leave Submission
**Endpoint:** `POST /api/leave-submissions`

**Description:** Submit leave request with attachment.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Request Body (form-data):**
```
date: "2026-07-25" (required, date format YYYY-MM-DD)
type: "cuti" (required, enum: cuti, izin, sakit)
attachment: [file] (required, image, max 2MB, jpeg/jpg/png/webp)
```

**Type Options:**
- `cuti` - Cuti tahunan/berbayar
- `izin` - Izin pribadi
- `sakit` - Sakit dengan surat dokter

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Surat berhasil diunggah.",
  "data": {
    "id": 1,
    "user_id": 1,
    "date": "2026-07-25",
    "type": "cuti",
    "attachment_path": "leave_attachments/xyz789.jpg",
    "created_at": "2026-07-24T15:00:00.000000Z",
    "updated_at": "2026-07-24T15:00:00.000000Z"
  }
}
```

**Access:** Worker roles only

---

## Error Response Format

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error message",
  "data": null
}
```

Or for validation errors:

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "field_name": ["Error message"]
  }
}
```

---

## Common HTTP Status Codes

- `200 OK` - Request successful
- `201 Created` - Resource created successfully
- `400 Bad Request` - Validation error or business logic violation
- `401 Unauthorized` - Missing or invalid authentication token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Duplicate resource or constraint violation
- `422 Unprocessable Entity` - Validation error
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

---

## Rate Limiting

- **Login endpoint:** 5 attempts per 5 minutes per IP
- **Report submission:** Rate limited (configurable)
- Other endpoints may have rate limiting based on configuration

---

## File Upload Specifications

All file uploads must be:
- Format: JPEG, JPG, PNG, or WebP
- Maximum size: 2MB (2048 KB)
- Content-Type: image/jpeg, image/jpg, image/png, or image/webp

**Storage Paths:**
- Report photos: `storage/app/public/reports/`
- Clock-in photos: `storage/app/public/attendances/clock_in/`
- Clock-out photos: `storage/app/public/attendances/clock_out/`
- Leave attachments: `storage/app/public/leave_attachments/`

---

## User Roles

- `admin` - Full access to all features
- `viewer` - Read-only access
- `housekeeping` - Worker role for housekeeping tasks
- `teknisi` - Worker role for technical tasks
- `security` - Worker role for security tasks

---

## Environment Variables

Make sure to configure these in your `.env` file:

```env
APP_URL=http://localhost:8000
DB_DATABASE=sobm
FILESYSTEM_DISK=public
```

---

## Testing Tips

1. **Authentication:** First call `/api/login` to get token, then use it in Authorization header
2. **Geofence Testing:** Use coordinates within 100m of office for attendance testing
3. **Schedule Testing:** Create schedules first before testing reports
4. **File Uploads:** Test with actual image files under 2MB
5. **Date Formats:** Use ISO 8601 format for dates (YYYY-MM-DD)
6. **Pagination:** Reports endpoint returns 20 items per page by default

---

## Postman Collection Import

To use this in Postman:

1. Copy the JSON collection below
2. In Postman, click "Import"
3. Paste the JSON and import
4. Update the base URL variable in the collection

```json
{
  "info": {
    "name": "SOBM API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:8000/api",
      "type": "string"
    },
    {
      "key": "token",
      "value": "",
      "type": "string"
    }
  ],
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"employee_id\": \"EMP001\",\n  \"password\": \"password123\"\n}"
            },
            "url": {
              "raw": "{{base_url}}/login",
              "host": ["{{base_url}}"],
              "path": ["login"]
            }
          }
        },
        {
          "name": "Logout",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{base_url}}/logout",
              "host": ["{{base_url}}"],
              "path": ["logout"]
            }
          }
        },
        {
          "name": "Get Current User",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{base_url}}/user",
              "host": ["{{base_url}}"],
              "path": ["user"]
            }
          }
        }
      ]
    },
    {
      "name": "Schedules",
      "item": [
        {
          "name": "Get User Schedules",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{base_url}}/schedules",
              "host": ["{{base_url}}"],
              "path": ["schedules"]
            }
          }
        }
      ]
    },
    {
      "name": "Reports",
      "item": [
        {
          "name": "Create Report",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "formdata",
              "formdata": [
                {
                  "key": "schedule_id",
                  "value": "1",
                  "type": "text"
                },
                {
                  "key": "check_in_latitude",
                  "value": "-0.94326885",
                  "type": "text"
                },
                {
                  "key": "check_in_longitude",
                  "value": "100.35396392",
                  "type": "text"
                },
                {
                  "key": "photo",
                  "type": "file",
                  "src": []
                },
                {
                  "key": "condition_status",
                  "value": "Aman/Bersih",
                  "type": "text"
                },
                {
                  "key": "work_description",
                  "value": "Pembersihan selesai",
                  "type": "text"
                },
                {
                  "key": "notes",
                  "value": "",
                  "type": "text"
                }
              ]
            },
            "url": {
              "raw": "{{base_url}}/reports",
              "host": ["{{base_url}}"],
              "path": ["reports"]
            }
          }
        },
        {
          "name": "Get Reports",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{base_url}}/reports?role=housekeeping&date=2026-07-24",
              "host": ["{{base_url}}"],
              "path": ["reports"],
              "query": [
                {
                  "key": "role",
                  "value": "housekeeping"
                },
                {
                  "key": "date",
                  "value": "2026-07-24"
                }
              ]
            }
          }
        }
      ]
    },
    {
      "name": "Attendance",
      "item": [
        {
          "name": "Get Today's Attendance",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{base_url}}/attendance/today",
              "host": ["{{base_url}}"],
              "path": ["attendance", "today"]
            }
          }
        },
        {
          "name": "Clock In",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "formdata",
              "formdata": [
                {
                  "key": "latitude",
                  "value": "-0.94326885",
                  "type": "text"
                },
                {
                  "key": "longitude",
                  "value": "100.35396392",
                  "type": "text"
                },
                {
                  "key": "photo",
                  "type": "file",
                  "src": []
                },
                {
                  "key": "notes",
                  "value": "",
                  "type": "text"
                }
              ]
            },
            "url": {
              "raw": "{{base_url}}/attendance/clock-in",
              "host": ["{{base_url}}"],
              "path": ["attendance", "clock-in"]
            }
          }
        },
        {
          "name": "Clock Out",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "formdata",
              "formdata": [
                {
                  "key": "latitude",
                  "value": "-0.94326885",
                  "type": "text"
                },
                {
                  "key": "longitude",
                  "value": "100.35396392",
                  "type": "text"
                },
                {
                  "key": "photo",
                  "type": "file",
                  "src": []
                }
              ]
            },
            "url": {
              "raw": "{{base_url}}/attendance/clock-out",
              "host": ["{{base_url}}"],
              "path": ["attendance", "clock-out"]
            }
          }
        }
      ]
    },
    {
      "name": "Issues",
      "item": [
        {
          "name": "Update Issue Status",
          "request": {
            "method": "PATCH",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"status\": \"resolved\",\n  \"resolution_notes\": \"AC sudah diperbaiki\"\n}"
            },
            "url": {
              "raw": "{{base_url}}/issues/1/status",
              "host": ["{{base_url}}"],
              "path": ["issues", "1", "status"]
            }
          }
        }
      ]
    },
    {
      "name": "Leave Submissions",
      "item": [
        {
          "name": "Create Leave Submission",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{token}}"
              }
            ],
            "body": {
              "mode": "formdata",
              "formdata": [
                {
                  "key": "date",
                  "value": "2026-07-25",
                  "type": "text"
                },
                {
                  "key": "type",
                  "value": "cuti",
                  "type": "text"
                },
                {
                  "key": "attachment",
                  "type": "file",
                  "src": []
                }
              ]
            },
            "url": {
              "raw": "{{base_url}}/leave-submissions",
              "host": ["{{base_url}}"],
              "path": ["leave-submissions"]
            }
          }
        }
      ]
    }
  ]
}
```

---

## Notes

- All timestamps are in UTC timezone
- Soft delete is enabled for attendances (deleted records are marked with `deleted_at`)
- All file uploads are stored in the `public` disk
- Geofence calculations use Haversine formula for accurate distance measurement
- The API uses Laravel Sanctum for token-based authentication
