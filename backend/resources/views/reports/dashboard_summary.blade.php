<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Laporan Dashboard Monitoring</title>
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
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 15px;
            border-bottom: 3px solid #1e40af;
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
        .period {
            text-align: center;
            margin-bottom: 20px;
            padding: 10px;
            background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
            color: white;
            border-radius: 5px;
            font-weight: bold;
        }
        .section {
            margin-top: 30px;
            margin-bottom: 20px;
        }
        .section h3 {
            background: linear-gradient(135deg, #1e40af 0%, #3b82f6 100%);
            color: white;
            padding: 12px;
            font-size: 14px;
            margin-bottom: 15px;
            border-radius: 5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        .stat-box {
            border: 2px solid #1e40af;
            padding: 20px;
            text-align: center;
            border-radius: 8px;
            background: linear-gradient(135deg, #f8fafc 0%, #e0e7ff 100%);
        }
        .stat-box .label {
            font-weight: 600;
            margin-bottom: 8px;
            color: #1e40af;
            font-size: 11px;
            text-transform: uppercase;
        }
        .stat-box .value {
            font-size: 32px;
            font-weight: bold;
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
            font-weight: 600;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: 1px solid #1e3a8a;
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
    </style>
</head>
<body>
    <div class="header">
        <h1>Laporan Dashboard Monitoring Operasional</h1>
        <h2>Sistem Operasional Building Management (SOBM)</h2>
        <div class="subtitle">Sistem Informasi Manajemen Operasional Gedung Terintegrasi</div>
    </div>

    <div class="period">
        Periode: {{ $period['start_date'] }} s/d {{ $period['end_date'] }}
    </div>

    <div class="section">
        <h3>Statistik Umum</h3>
        <div class="stats-grid">
            <div class="stat-box">
                <div class="label">Total Pengguna</div>
                <div class="value">{{ $statistics['total_users'] }}</div>
            </div>
            <div class="stat-box">
                <div class="label">Total Absensi</div>
                <div class="value">{{ $statistics['total_attendances'] }}</div>
            </div>
            <div class="stat-box">
                <div class="label">Total Laporan Pekerjaan</div>
                <div class="value">{{ $statistics['total_reports'] }}</div>
            </div>
            <div class="stat-box">
                <div class="label">Total Kendala</div>
                <div class="value">{{ $statistics['total_issues'] }}</div>
            </div>
            <div class="stat-box">
                <div class="label">Total Pengajuan Cuti</div>
                <div class="value">{{ $statistics['total_leave_requests'] }}</div>
            </div>
        </div>
    </div>

    <div class="section">
        <h3>Absensi Berdasarkan Status</h3>
        <table>
            <thead>
                <tr>
                    <th>Status</th>
                    <th>Jumlah</th>
                </tr>
            </thead>
            <tbody>
                @foreach($attendance_by_status as $status => $count)
                <tr>
                    <td>{{ ucfirst($status) }}</td>
                    <td>{{ $count }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    <div class="section">
        <h3>Laporan Pekerjaan Berdasarkan Kondisi</h3>
        <table>
            <thead>
                <tr>
                    <th>Kondisi</th>
                    <th>Jumlah</th>
                </tr>
            </thead>
            <tbody>
                @foreach($reports_by_condition as $condition => $count)
                <tr>
                    <td>{{ $condition }}</td>
                    <td>{{ $count }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    <div class="section">
        <h3>Kendala Berdasarkan Status Penyelesaian</h3>
        <table>
            <thead>
                <tr>
                    <th>Status</th>
                    <th>Jumlah</th>
                </tr>
            </thead>
            <tbody>
                @foreach($issues_by_status as $isResolved => $count)
                <tr>
                    <td>{{ $isResolved ? 'Terselesaikan' : 'Belum Terselesaikan' }}</td>
                    <td>{{ $count }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>

    <div class="footer">
        <p><strong>Sistem Operasional Building Management (SOBM)</strong></p>
        <p>Dicetak otomatis oleh sistem pada {{ now()->format('d F Y H:i:s') }}</p>
        <p>© 2026 SOBM - All Rights Reserved</p>
    </div>
</body>
</html>
