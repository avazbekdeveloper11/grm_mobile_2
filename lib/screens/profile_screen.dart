// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/strings.dart';
import '../services/api_service.dart';
import '../utils/order_number.dart';
import '../widgets/order_card.dart';
import '../widgets/status_badge.dart';
import 'admin/order_detail_screen.dart';
import 'login_screen.dart';

// Standalone screen (admin dan ochganda)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: ProfileBody());
}

// Tab ichida ishlatiladigan widget (navbar saqlanadi)
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final tp = context.watch<ThemeProvider>();
    final s = S(tp.language);
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<OrderProvider>();

    final myOrders = user.role == UserRole.worker
        ? provider.ordersForWorker(user.id)
        : provider.ordersForDriver(user.id);

    final activeCount = myOrders
        .where((o) => o.status != OrderStatus.yetkazildi)
        .length;
    final doneCount = myOrders
        .where((o) => o.status == OrderStatus.yetkazildi)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Profil ────────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role == UserRole.worker ? s.workerRole : s.driverRole,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.login}',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ─── Statistika ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: s.activeCount,
                value: '$activeCount',
                icon: Icons.pending_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: s.doneCount,
                value: '$doneCount',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: s.totalCount,
                value: '${myOrders.length}',
                icon: Icons.layers_outlined,
                color: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ─── Ko'rinish sozlamalari ─────────────────────────────────
        _SettingsCard(
          title: s.appearance,
          icon: Icons.palette_outlined,
          children: [
            // Dark / Light
            _SettingsRow(
              icon: tp.isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              label: s.themeMode,
              trailing: Switch(
                value: tp.isDark,
                onChanged: (v) =>
                    tp.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
            ),
            const Divider(height: 1),
            // Til
            _SettingsRow(
              icon: Icons.language,
              label: s.languageLabel,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LangChip("O'zbek", AppLanguage.uzLatin, tp),
                  const SizedBox(width: 6),
                  _LangChip("Кирилл", AppLanguage.uzCyrillic, tp),
                ],
              ),
            ),
            const Divider(height: 1),
            // Shrift o'lchami
            _FontSizeRow(tp: tp),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Mening buyurtmalarim ─────────────────────────────────
        if (myOrders.isNotEmpty) ...[
          _SettingsCard(
            title: s.myOrders,
            icon: Icons.receipt_long_outlined,
            children: [
              ...myOrders
                  .where((o) => o.status != OrderStatus.yetkazildi)
                  .take(5)
                  .map((o) => _OrderMiniTile(order: o)),
              if (myOrders.any((o) => o.status != OrderStatus.yetkazildi))
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _AllOrdersScreen(
                        orders: myOrders,
                        userName: user.name,
                      ),
                    ),
                  ),
                  child: Text(s.viewAllOrders),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // ─── Parolni o'zgartirish ─────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(s.changePassword),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _changePassword(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 8),

        // ─── Chiqish ──────────────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              s.logoutButton,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _logout(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false, showNew = false, showConfirm = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(s.changePassword),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: !showCurrent,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: s.currentPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(showCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setLocal(() => showCurrent = !showCurrent),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: !showNew,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: s.newPassword,
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(showNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setLocal(() => showNew = !showNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: !showConfirm,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: s.confirmPassword,
                  prefixIcon: const Icon(Icons.check_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setLocal(() => showConfirm = !showConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                ),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.bekor),
            ),
            FilledButton(
              onPressed: () async {
                final current = currentCtrl.text.trim();
                final newPass = newCtrl.text.trim();
                final confirm = confirmCtrl.text.trim();

                if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(s.fillAllFields),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (newPass != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(s.passwordMismatch),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                if (newPass.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(s.passwordMinLength),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await context.read<ApiService>().changePassword(current, newPass);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(s.passwordChanged),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${s.error}: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
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

  Future<void> _logout(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}

// ─── All orders screen ─────────────────────────────────────────────────────────

class _AllOrdersScreen extends StatelessWidget {
  final List<OrderModel> orders;
  final String userName;
  const _AllOrdersScreen({required this.orders, required this.userName});

  @override
  Widget build(BuildContext context) {
    final sorted = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: Text("$userName — buyurtmalar"), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sorted.length,
        itemBuilder: (ctx, i) => OrderCard(
          order: sorted[i],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(order: sorted[i], readOnly: true),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Order mini tile ───────────────────────────────────────────────────────────

class _OrderMiniTile extends StatelessWidget {
  final OrderModel order;
  const _OrderMiniTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, readOnly: true)),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: Color(order.status.colorValue),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        orderNumber(order.id),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Text(
                    order.address,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _LangChip extends StatelessWidget {
  final String label;
  final AppLanguage lang;
  final ThemeProvider tp;
  const _LangChip(this.label, this.lang, this.tp);

  @override
  Widget build(BuildContext context) {
    final selected = tp.language == lang;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => tp.setLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _FontSizeRow extends StatelessWidget {
  final ThemeProvider tp;
  const _FontSizeRow({required this.tp});

  static const _scales = [
    (label: 'A', scale: 0.9),
    (label: 'A', scale: 1.0),
    (label: 'A', scale: 1.2),
    (label: 'A', scale: 1.4),
  ];
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.read<ThemeProvider>().language);
    final names = [s.fontSmall, s.fontNormal, s.fontLarge, s.fontXLarge];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                s.fontSizeLabel,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _scales.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = (tp.fontScale - item.scale).abs() < 0.05;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => tp.setFontScale(item.scale),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primary
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? cs.primary : cs.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            item.label,
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 12 + i * 4.0,
                              fontWeight: FontWeight.bold,
                              color: selected ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            names[i],
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 9,
                              color: selected
                                  ? cs.onPrimary.withValues(alpha: 0.8)
                                  : cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
