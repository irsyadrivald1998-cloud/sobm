<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laporan Data Pengguna</title>
    <style>
        @page {
            margin: 20mm;
            @bottom-center {
                content: "Halaman " counter(page) " dari " counter(pages);
                font-size: 10px;
                color: #666;
            }
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            font-size: 11px;
            margin: 0;
            padding: 0;
            color: #333;
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 3px solid #1e40af;
        }
        .header .logo {
            width: 70px;
            height: 70px;
            margin-right: 15px;
            flex-shrink: 0;
        }
        .header .title-group {
            text-align: left;
            flex: 1;
        }
        .header h1 {
            font-size: 24px;
            font-weight: bold;
            color: #1e40af;
            margin: 0 0 5px 0;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .header h2 {
            font-size: 14px;
            font-weight: normal;
            color: #666;
            margin: 0;
        }
        .header .subtitle {
            font-size: 12px;
            color: #888;
            margin-top: 5px;
        }
        .report-info {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            padding: 10px;
            background-color: #f8fafc;
            border-radius: 5px;
            border-left: 4px solid #1e40af;
        }
        .report-info div {
            font-size: 11px;
            color: #555;
        }
        .report-info strong {
            color: #1e40af;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        thead {
            background-color: #1e3a8a;
            color: white;
        }
        th {
            padding: 12px 10px;
            text-align: left;
            font-weight: 700;
            font-size: 13px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: 1px solid #1e3a8a;
            color: #ffffff !important;
            background-color: #1e3a8a !important;
        }
        td {
            padding: 10px;
            border: 1px solid #e5e7eb;
            text-align: left;
        }
        tbody tr:nth-child(even) {
            background-color: #f9fafb;
        }
        tbody tr:hover {
            background-color: #e0e7ff;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #e5e7eb;
            font-size: 10px;
            color: #666;
        }
        .footer p {
            margin: 3px 0;
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 9px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-admin { background-color: #dcfce7; color: #166534; }
        .badge-viewer { background-color: #dbeafe; color: #1e40af; }
        .badge-housekeeping { background-color: #fef3c7; color: #92400e; }
        .badge-teknisi { background-color: #fce7f3; color: #9d174d; }
        .badge-security { background-color: #fee2e2; color: #991b1b; }
        .badge-osb { background-color: #e0e7ff; color: #3730a3; }
        .badge-resepsionis { background-color: #f3e8ff; color: #6b21a8; }
        .badge-bm { background-color: #ccfbf1; color: #115e59; }
        .badge-user { background-color: #f1f5f9; color: #475569; }
    </style>
</head>
<body>
    <div class="header">
        @if($logoData)
            <img src="{{ $logoData }}" alt="SOBM Logo" class="logo">
        @endif
        <div class="title-group">
            <h1>Laporan Data Pengguna</h1>
            <h2>Sistem Operasional Building Management (SOBM)</h2>
            <div class="subtitle">Sistem Informasi Manajemen Operasional Gedung Terintegrasi</div>
        </div>
    </div>

    <div class="report-info">
        <div><strong>Tanggal Cetak:</strong> {{ now()->format('d F Y') }}</div>
        <div><strong>Waktu Cetak:</strong> {{ now()->format('H:i:s') }}</div>
        <div><strong>Total Data:</strong> {{ $users->count() }} Pengguna</div>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 50px; color: white; background-color: #1e3a8a;">No</th>
                <th style="color: white; background-color: #1e3a8a;">Employee ID</th>
                <th style="color: white; background-color: #1e3a8a;">Nama Lengkap</th>
                <th style="color: white; background-color: #1e3a8a;">Role</th>
                <th style="color: white; background-color: #1e3a8a;">Email</th>
                <th style="color: white; background-color: #1e3a8a;">Tanggal Dibuat</th>
            </tr>
        </thead>
        <tbody>
            @foreach($users as $index => $user)
            <tr>
                <td style="text-align: center;">{{ $index + 1 }}</td>
                <td>{{ $user->employee_id }}</td>
                <td>{{ $user->name }}</td>
                <td><span class="badge badge-{{ $user->role }}">{{ ucfirst($user->role) }}</span></td>
                <td>{{ $user->email }}</td>
                <td>{{ $user->created_at->format('d/m/Y') }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>

    <div class="footer">
        <p><strong>Sistem Operasional Building Management (SOBM)</strong></p>
        <p>Dicetak otomatis oleh sistem pada {{ now()->format('d F Y H:i:s') }}</p>
        <p>© 2026 SOBM - All Rights Reserved</p>
    </div>
</body>
</html>
