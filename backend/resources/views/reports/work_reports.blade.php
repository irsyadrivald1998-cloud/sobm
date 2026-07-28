<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laporan Pekerjaan</title>
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
            width: 80px;
            height: 80px;
            margin-right: 20px;
        }
        .header .title-group {
            text-align: center;
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
            background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
            color: white;
        }
        th {
            padding: 12px 10px;
            text-align: left;
            font-weight: 700;
            font-size: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: 1px solid #1e3a8a;
            color: #ffffff !important;
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
        .badge-aman { background-color: #dcfce7; color: #166534; }
        .badge-kendala { background-color: #fee2e2; color: #991b1b; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Laporan Pekerjaan</h1>
        <h2>Sistem Operasional Building Management (SOBM)</h2>
        <div class="subtitle">Sistem Informasi Manajemen Operasional Gedung Terintegrasi</div>
    </div>

    <div class="report-info">
        <div><strong>Tanggal Cetak:</strong> {{ now()->format('d F Y') }}</div>
        <div><strong>Waktu Cetak:</strong> {{ now()->format('H:i:s') }}</div>
        <div><strong>Total Data:</strong> {{ $reports->count() }} Laporan</div>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width: 50px;">No</th>
                <th>Tanggal</th>
                <th>Nama Karyawan</th>
                <th>Role</th>
                <th>Checkpoint</th>
                <th>Kategori Tugas</th>
                <th>Kondisi</th>
                <th>Deskripsi Pekerjaan</th>
                <th>Catatan</th>
                <th>Kendala</th>
            </tr>
        </thead>
        <tbody>
            @foreach($reports as $index => $report)
            <tr>
                <td style="text-align: center;">{{ $index + 1 }}</td>
                <td>{{ $report->created_at ? $report->created_at->format('d/m/Y H:i') : '-' }}</td>
                <td>{{ $report->schedule && $report->schedule->user ? $report->schedule->user->name : '-' }}</td>
                <td>{{ $report->schedule && $report->schedule->user ? ucfirst($report->schedule->user->role) : '-' }}</td>
                <td>{{ $report->schedule && $report->schedule->checkpoint ? $report->schedule->checkpoint->name : '-' }}</td>
                <td>{{ $report->schedule && $report->schedule->taskCategory ? $report->schedule->taskCategory->task_name : '-' }}</td>
                <td><span class="badge badge-{{ str_replace('/', '-', strtolower($report->condition_status)) }}">{{ $report->condition_status }}</span></td>
                <td>{{ $report->work_description }}</td>
                <td>{{ $report->notes ?? '-' }}</td>
                <td>{{ $report->issue ? $report->issue->issue_description : '-' }}</td>
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
