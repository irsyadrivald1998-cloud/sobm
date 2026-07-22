import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'theme_notifier.dart';
import 'api_service.dart';
import 'main.dart' show ThemeProvider;

// ─────────────────────────────────────────────────────────────────────────────
//  ProfilePage — user account & settings
// ─────────────────────────────────────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _api.getUser();
    setState(() { _user = data; _isLoading = false; });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              nav.pop();
              await _api.logout();
              nav.pushReplacementNamed('/');
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final themeN   = ThemeProvider.of(context);

    final name       = _user?['name']        as String? ?? 'Pekerja';
    final employeeId = _user?['employee_id'] as String? ?? '-';
    final role       = (_user?['role']       as String? ?? '-').toUpperCase();
    final email      = _user?['email']       as String? ?? '-';

    // Initials avatar
    final parts    = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.substring(0, name.length.clamp(0, 2)).toUpperCase();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBrand))
          : CustomScrollView(
              slivers: [
                // ── Hero Header ───────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: cs.surface,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _ProfileHeader(
                      name:       name,
                      role:       role,
                      initials:   initials,
                      isDark:     isDark,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(0.5),
                    child: Divider(height: 0.5, color: cs.outlineVariant),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spMd),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ── Account Info ────────────────────────────────────────
                      _SectionHeader('Informasi Akun'),
                      _InfoCard(entries: [
                        _InfoEntry(Icons.badge_outlined,     'Employee ID', employeeId),
                        _InfoEntry(Icons.email_outlined,     'Email',       email),
                        _InfoEntry(Icons.work_outline,       'Role',        role),
                        _InfoEntry(Icons.corporate_fare_outlined, 'Perusahaan', 'SOBM Facility'),
                      ]),

                      // ── Stats ────────────────────────────────────────────────
                      const SizedBox(height: AppTheme.spMd),
                      _SectionHeader('Statistik Tugas'),
                      _StatsRow(schedules: const []),

                      // ── Preferences ─────────────────────────────────────────
                      const SizedBox(height: AppTheme.spMd),
                      _SectionHeader('Preferensi'),
                      _SettingsCard(children: [
                        _SwitchTile(
                          icon:     Icons.light_mode_outlined,
                          iconColor: const Color(0xFFFBBF24),
                          title:    'Mode Terang',
                          subtitle: 'Aktifkan tampilan light mode',
                          value:    themeN.isLight,
                          onChanged: (_) => themeN.toggle(),
                        ),
                        _DividerLine(),
                        _NavTile(
                          icon:     Icons.notifications_outlined,
                          iconColor: AppTheme.tertiary,
                          title:    'Notifikasi',
                          subtitle: 'Kelola preferensi notifikasi',
                          onTap:    () => _showComingSoon(context),
                        ),
                        _DividerLine(),
                        _NavTile(
                          icon:     Icons.language_outlined,
                          iconColor: const Color(0xFF7BD1F8),
                          title:    'Bahasa',
                          subtitle: 'Bahasa Indonesia',
                          onTap:    () => _showComingSoon(context),
                        ),
                      ]),

                      // ── Security ─────────────────────────────────────────────
                      const SizedBox(height: AppTheme.spMd),
                      _SectionHeader('Keamanan'),
                      _SettingsCard(children: [
                        _NavTile(
                          icon:     Icons.lock_outline,
                          iconColor: AppTheme.statusWarning,
                          title:    'Ubah Password',
                          subtitle: 'Perbarui kata sandi Anda',
                          onTap:    () => _showChangePassword(context),
                        ),
                        _DividerLine(),
                        _NavTile(
                          icon:     Icons.fingerprint,
                          iconColor: AppTheme.primary,
                          title:    'Biometrik',
                          subtitle: 'Masuk dengan sidik jari / Face ID',
                          onTap:    () => _showComingSoon(context),
                        ),
                        _DividerLine(),
                        _NavTile(
                          icon:     Icons.history_outlined,
                          iconColor: AppTheme.outline,
                          title:    'Riwayat Login',
                          subtitle: 'Lihat aktivitas masuk akun',
                          onTap:    () => _showComingSoon(context),
                        ),
                      ]),

                      // ── App Info ──────────────────────────────────────────────
                      const SizedBox(height: AppTheme.spMd),
                      _SectionHeader('Tentang Aplikasi'),
                      _SettingsCard(children: [
                        _NavTile(
                          icon:     Icons.info_outline,
                          iconColor: AppTheme.outline,
                          title:    'Versi Aplikasi',
                          subtitle: 'v1.0.0 (build 1)',
                          onTap:    null,
                          showArrow: false,
                        ),
                        _DividerLine(),
                        _NavTile(
                          icon:     Icons.description_outlined,
                          iconColor: AppTheme.outline,
                          title:    'Kebijakan Privasi',
                          subtitle: 'Baca kebijakan data kami',
                          onTap:    () => _showComingSoon(context),
                        ),
                        _DividerLine(),
                        _NavTile(
                          icon:     Icons.help_outline,
                          iconColor: AppTheme.tertiary,
                          title:    'Bantuan & Dukungan',
                          subtitle: 'Hubungi tim teknis',
                          onTap:    () => _showComingSoon(context),
                        ),
                      ]),

                      // ── Logout ────────────────────────────────────────────────
                      const SizedBox(height: AppTheme.spXl),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout, color: AppTheme.alertCritical),
                          label: const Text(
                            'Keluar Akun',
                            style: TextStyle(color: AppTheme.alertCritical, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.alertCritical, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spXl),

                      // Version footer
                      Center(
                        child: Text(
                          'SOBM Mobile Check-In\nv1.0.0 © 2026',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: cs.outlineVariant),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spXl),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  void _showComingSoon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Fitur ini akan segera hadir.')),
    );
  }

  void _showChangePassword(BuildContext ctx) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final conCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldCtrl, obscureText: true,
                decoration: const InputDecoration(hintText: 'Password lama')),
            const SizedBox(height: AppTheme.spSm),
            TextField(controller: newCtrl, obscureText: true,
                decoration: const InputDecoration(hintText: 'Password baru')),
            const SizedBox(height: AppTheme.spSm),
            TextField(controller: conCtrl, obscureText: true,
                decoration: const InputDecoration(hintText: 'Konfirmasi password baru')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showComingSoon(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String role;
  final String initials;
  final bool   isDark;
  const _ProfileHeader({
    required this.name, required this.role,
    required this.initials, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.surfaceLowest, AppTheme.surface]
              : [AppTheme.lightSurfaceLow, AppTheme.lightSurface],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spXl, vertical: AppTheme.spMd),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle
              Stack(
                children: [
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBrand.withOpacity(0.15),
                      border: Border.all(
                          color: AppTheme.primaryBrand.withOpacity(0.6),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(initials,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBrand,
                          )),
                    ),
                  ),
                  // Online dot
                  Positioned(
                    right: 4, bottom: 4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.statusOk,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark
                                ? AppTheme.surfaceLowest
                                : AppTheme.lightSurface,
                            width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spMd),
              Text(name,
                  style: AppTheme.titleLg.copyWith(
                    color: isDark ? AppTheme.onSurface : AppTheme.lightOnSurface,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: AppTheme.spXs),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spSm, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBrand.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                      color: AppTheme.primaryBrand.withOpacity(0.4), width: 1),
                ),
                child: Text(role,
                    style: AppTheme.labelSm.copyWith(
                        color: AppTheme.primaryBrand, letterSpacing: 1.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
          left: AppTheme.spXs, bottom: AppTheme.spSm),
      child: Row(children: [
        Container(width: 3, height: 14,
            decoration: BoxDecoration(
                color: AppTheme.primaryBrand,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: AppTheme.spSm),
        Text(text,
            style: AppTheme.labelMd.copyWith(
                color: cs.onSurfaceVariant, letterSpacing: 0.8)),
      ]),
    );
  }
}

// ── Info card ────────────────────────────────────────────────────────────────
class _InfoEntry {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoEntry(this.icon, this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final List<_InfoEntry> entries;
  const _InfoCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final isLast = e.key == entries.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spMd, vertical: AppTheme.spSm + 4),
              child: Row(children: [
                Icon(e.value.icon, size: 18, color: AppTheme.primaryBrand),
                const SizedBox(width: AppTheme.spMd),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.label,
                      style: AppTheme.labelSm.copyWith(
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(e.value.value,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                ]),
              ]),
            ),
            if (!isLast) Divider(height: 0.5, color: cs.outlineVariant),
          ]);
        }).toList(),
      ),
    );
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final List<dynamic> schedules;
  const _StatsRow({required this.schedules});

  @override
  Widget build(BuildContext context) {
    final cs        = Theme.of(context).colorScheme;
    final completed = schedules.where((s) => s['status'] == 'completed').length;
    final pending   = schedules.where((s) => s['status'] == 'pending').length;
    final total     = schedules.length;

    final items = [
      _StatItem(total.toString(),     'Total',     AppTheme.tertiary),
      _StatItem(completed.toString(), 'Selesai',   AppTheme.statusOk),
      _StatItem(pending.toString(),   'Pending',   AppTheme.statusWarning),
      _StatItem('100%',               'Akurasi',   AppTheme.primaryBrand),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spMd),
              decoration: BoxDecoration(
                border: Border(
                  right: isLast
                      ? BorderSide.none
                      : BorderSide(color: cs.outlineVariant, width: 0.5),
                ),
              ),
              child: Column(children: [
                Text(e.value.value,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: e.value.color)),
                const SizedBox(height: 2),
                Text(e.value.label,
                    style: AppTheme.labelSm.copyWith(
                        color: cs.onSurfaceVariant)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  final String value, label;
  final Color  color;
  const _StatItem(this.value, this.label, this.color);
}

// ── Settings card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 0.5,
        color: Theme.of(context).colorScheme.outlineVariant);
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final bool     value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spMd, vertical: AppTheme.spSm),
      child: Row(children: [
        _IconBox(icon: icon, color: iconColor),
        const SizedBox(width: AppTheme.spMd),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
            Text(subtitle, style: AppTheme.labelMd.copyWith(color: cs.onSurfaceVariant)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryBrand,
        ),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final VoidCallback? onTap;
  final bool      showArrow;

  const _NavTile({
    required this.icon, required this.iconColor,
    required this.title, required this.subtitle,
    required this.onTap, this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spMd, vertical: AppTheme.spSm + 2),
        child: Row(children: [
          _IconBox(icon: icon, color: iconColor),
          const SizedBox(width: AppTheme.spMd),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              Text(subtitle, style: AppTheme.labelMd.copyWith(color: cs.onSurfaceVariant)),
            ],
          )),
          if (showArrow)
            Icon(Icons.chevron_right, color: cs.outline, size: 20),
        ]),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color    color;
  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
