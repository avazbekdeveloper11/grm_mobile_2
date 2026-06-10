// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import 'services_screen.dart';
import 'manage_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Future<void> _showChangePassword(BuildContext ctx, S s) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showC = false, showN = false, showCf = false;

    await showDialog(
      context: ctx,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.changePassword),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: currentCtrl,
              obscureText: !showC,
              decoration: InputDecoration(
                labelText: s.currentPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(showC ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setLocal(() => showC = !showC),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: !showN,
              decoration: InputDecoration(
                labelText: s.newPassword,
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(showN ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setLocal(() => showN = !showN),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: !showCf,
              decoration: InputDecoration(
                labelText: s.confirmPassword,
                prefixIcon: const Icon(Icons.check_outlined),
                suffixIcon: IconButton(
                  icon: Icon(showCf ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setLocal(() => showCf = !showCf),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
            ),
          ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: Text(s.cancel)),
            FilledButton(
              onPressed: () async {
                final cur = currentCtrl.text.trim();
                final nw = newCtrl.text.trim();
                final cf = confirmCtrl.text.trim();
                if (cur.isEmpty || nw.isEmpty || cf.isEmpty) {
                  _snack(s.fillAllFields, error: true); return;
                }
                if (nw != cf) {
                  _snack(s.passwordMismatch, error: true); return;
                }
                if (nw.length < 4) {
                  _snack(s.passwordMinLength, error: true); return;
                }
                Navigator.pop(dctx);
                try {
                  await context.read<ApiService>().changePassword(cur, nw);
                  _snack(s.passwordChanged);
                } catch (e) {
                  _snack('${s.error}: $e', error: true);
                }
              },
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentCtrl.dispose();
      newCtrl.dispose();
      confirmCtrl.dispose();
    });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final s = S(themeProvider.language);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ─── Ko'rinish ────────────────────────────────────────────
          _NavTile(
            icon: Icons.palette_outlined,
            title: s.appearance,
            subtitle: '${s.themeMode} · ${s.languageLabel} · ${s.fontSizeLabel}',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const _AppearanceScreen())),
          ),
          const SizedBox(height: 14),

          // ─── Xodimlar ─────────────────────────────────────────────
          _NavTile(
            icon: Icons.people_outline,
            title: s.manageUsers,
            subtitle: '${s.workers} & ${s.drivers}',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
          ),
          const SizedBox(height: 14),

          // ─── Xizmatlar ────────────────────────────────────────────
          _NavTile(
            icon: Icons.category_outlined,
            title: s.servicesManagement,
            subtitle: s.servicesDesc,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServicesScreen())),
          ),
          const SizedBox(height: 14),

          // ─── Avto SMS ─────────────────────────────────────────────
          _NavTile(
            icon: Icons.sms_outlined,
            title: s.smsSettings,
            subtitle: s.smsInfo,
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _SmsScreen())),
          ),
          const SizedBox(height: 14),

                  // ─── Parolni o'zgartirish ────────────────────────────
                  _Card(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline),
                      title: Text(s.changePassword),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showChangePassword(context, s),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── Logout ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final auth = context.read<AuthProvider>();
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text(s.logoutConfirm),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(s.no)),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: Text(s.yes),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await auth.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(s.logoutButton,
                          style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ─── Theme toggle ──────────────────────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _ThemeToggle({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.light_mode_outlined, size: 16, color: Colors.amber),
        const SizedBox(width: 6),
        Switch(
          value: isDark,
          onChanged: onChanged,
          // ignore: deprecated_member_use
          activeColor: cs.primary,
          thumbIcon: WidgetStateProperty.resolveWith((states) => Icon(
            states.contains(WidgetState.selected)
                ? Icons.dark_mode
                : Icons.light_mode,
            size: 14,
          )),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.dark_mode_outlined, size: 16, color: Colors.blueGrey),
      ],
    );
  }
}

// ─── Language button ───────────────────────────────────────────────────────────

class _LangButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.primary,
                fontSize: 14)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  const _InfoChip(this.text, {this.color, this.textColor});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color ?? cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 15, color: textColor ?? cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: textColor ?? cs.onPrimaryContainer,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ExRow extends StatelessWidget {
  final String size;
  final String price;
  const _ExRow(this.size, this.price);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(size, style: Theme.of(context).textTheme.bodySmall),
            Text(price,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
          ],
        ),
      );
}

class _FontSizeSelector extends StatelessWidget {
  final ThemeProvider tp;
  const _FontSizeSelector({required this.tp});

  static const _scales = [0.9, 1.0, 1.2, 1.4];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.read<ThemeProvider>().language);
    final names = [s.fontSmall, s.fontNormal, s.fontLarge, s.fontXLarge];
    return Row(
      children: _scales.asMap().entries.map((e) {
        final i = e.key;
        final scale = e.value;
        final o = (scale: scale, label: 'A', name: names[i]);
        final selected = (tp.fontScale - scale).abs() < 0.05;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
            child: GestureDetector(
              onTap: () => tp.setFontScale(scale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(children: [
                  Text(
                    o.label,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: 12.0 + i * 4,
                      fontWeight: FontWeight.bold,
                      color: selected ? cs.onPrimary : cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o.name,
                    textScaler: TextScaler.noScaling,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: selected
                          ? cs.onPrimary.withValues(alpha: 0.8)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Nav tile ──────────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Appearance sub-screen ────────────────────────────────────────────────────

class _AppearanceScreen extends StatelessWidget {
  const _AppearanceScreen();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final s = S(tp.language);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(s.appearance)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Tema ──────────────────────────────────────────────────
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHeader(icon: Icons.dark_mode_outlined, title: s.themeMode),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.light_mode_outlined, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(isDark ? s.darkMode : s.lightMode,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
                _ThemeToggle(
                  isDark: isDark,
                  onChanged: (dark) =>
                      tp.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.dark_mode_outlined, size: 16, color: Colors.blueGrey),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // ─── Til ───────────────────────────────────────────────────
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHeader(icon: Icons.language, title: s.languageLabel),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _LangButton(
                  label: "O'zbek\n(Lotin)",
                  selected: tp.language == AppLanguage.uzLatin,
                  onTap: () => tp.setLanguage(AppLanguage.uzLatin),
                )),
                const SizedBox(width: 10),
                Expanded(child: _LangButton(
                  label: "Ўзбек\n(Кирилл)",
                  selected: tp.language == AppLanguage.uzCyrillic,
                  onTap: () => tp.setLanguage(AppLanguage.uzCyrillic),
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 14),

          // ─── Shrift ────────────────────────────────────────────────
          _Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _SectionHeader(icon: Icons.text_fields, title: s.fontSizeLabel),
              const SizedBox(height: 14),
              _FontSizeSelector(tp: tp),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── SMS sub-screen ────────────────────────────────────────────────────────────

class _SmsScreen extends StatefulWidget {
  const _SmsScreen();
  @override
  State<_SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<_SmsScreen> {
  static const _defaultTemplate =
      "Hurmatli mijoz, buyumlaringiz tayyor! Yetkazib berish uchun bog'lanamiz. Gilam yuvish xizmati.";

  bool _loading = true;
  bool _smsEnabled = true;
  String _template = _defaultTemplate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await context.read<ApiService>().getSettings();
      final enabledVal = settings['sms_enabled'];
      _smsEnabled = enabledVal == null || enabledVal == 1 || enabledVal == '1';
      _template = settings['sms_template'] as String? ?? _defaultTemplate;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _template
        .replaceAll('{ism}', 'Alisher')
        .replaceAll('{ISM}', 'Alisher');
    final charCount = preview.length;
    final isOver = charCount > 160;

    return Scaffold(
      appBar: AppBar(title: Text(s.smsSettings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  children: [

                    // ── Qachon yuboriladi ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade600, Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(s.smsInfo,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.4))),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // ── Yoqish / O'chirish switch ──────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _smsEnabled
                            ? Colors.green.withValues(alpha: 0.08)
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _smsEnabled
                              ? Colors.green.shade300
                              : cs.outlineVariant,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _smsEnabled
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                            key: ValueKey(_smsEnabled),
                            color: _smsEnabled
                                ? Colors.green.shade600
                                : cs.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _smsEnabled ? s.smsSettings : s.smsSettings,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _smsEnabled
                                    ? Colors.green.shade700
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              _smsEnabled ? s.smsEnabledStatus : s.smsDisabledStatus,
                              style: TextStyle(
                                fontSize: 11,
                                color: _smsEnabled
                                    ? Colors.green.shade600
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )),
                        Switch(
                          value: _smsEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.green.shade500,
                          onChanged: (v) async {
                            setState(() => _smsEnabled = v);
                            try {
                              await context.read<ApiService>().updateSmsEnabled(v);
                            } catch (e) {
                              setState(() => _smsEnabled = !v);
                              _snack('${s.error}: $e', error: true);
                            }
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // ── SMS matni ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.smsTemplateLabel,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface)),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOver
                                ? Colors.red.shade50
                                : cs.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$charCount / 160',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOver ? Colors.red : cs.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _template,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: _defaultTemplate,
                        hintStyle: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: cs.primary, width: 2),
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      onChanged: (v) => setState(() => _template = v),
                    ),
                    const SizedBox(height: 16),

                    // ── Telefon preview ────────────────────────────────
                    Text(s.smsSample,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? cs.surfaceContainerHigh
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        // SMS icon
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sms,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(s.carpetWashing,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? cs.surfaceContainerHighest
                                    : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(14),
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                preview.isEmpty ? '...' : preview,
                                style: const TextStyle(
                                    fontSize: 13, height: 1.5),
                              ),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // ── Android eslatma ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.smsPermissionNote,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Saqlab qo'yish (pastda) ──────────────────────────────
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_rounded),
                    label: Text(s.saveSmsTemplate),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final t = _template.trim();
                      if (t.isEmpty) return;
                      try {
                        await context.read<ApiService>().updateSmsTemplate(t);
                        _snack(s.smsTemplateSaved);
                      } catch (e) {
                        _snack('${s.error}: $e', error: true);
                      }
                    },
                  ),
                ),
              ),
            ]),
    );
  }
}

