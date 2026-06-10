import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

/// Returns: (confirmed=true, driver) — tasdiqlandi
///          (confirmed=false, null) — bekor qilindi yoki yopildi
typedef DriverDialogResult = ({bool confirmed, UserModel? driver});

Future<DriverDialogResult> showSelectDriverDialog(
  BuildContext context, {
  String? currentDriverId,
}) async {
  final up = context.read<UserProvider>();
  if (up.workers.isEmpty) await up.loadUsers();
  final drivers = up.activeDrivers;

  if (!context.mounted) return (confirmed: false, driver: null);

  final result = await showModalBottomSheet<DriverDialogResult>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    isDismissible: true,
    builder: (ctx) => _SelectDriverSheet(
      drivers: drivers,
      currentDriverId: currentDriverId,
    ),
  );
  // Swipe bilan yopilsa null keladi — bekor deb hisoblaymiz
  return result ?? (confirmed: false, driver: null);
}

class _SelectDriverSheet extends StatefulWidget {
  final List<UserModel> drivers;
  final String? currentDriverId;
  const _SelectDriverSheet({required this.drivers, this.currentDriverId});

  @override
  State<_SelectDriverSheet> createState() => _SelectDriverSheetState();
}

class _SelectDriverSheetState extends State<_SelectDriverSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDriverId;
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(children: [
            Icon(Icons.local_shipping_outlined, color: cs.primary),
            const SizedBox(width: 10),
            Text(s.selectDeliveryDriver,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
          ]),
          const SizedBox(height: 4),
          Text(s.whoDelivers,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),

          // Driver list
          ...widget.drivers.map((d) {
            final isSelected = _selected == d.id;
            return GestureDetector(
              onTap: () => setState(() => _selected = d.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor:
                        isSelected ? cs.primary : cs.surfaceContainerHigh,
                    child: Text(d.name[0],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(d.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isSelected ? cs.onPrimaryContainer : cs.onSurface)),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: cs.primary),
                ]),
              ),
            );
          }),

          // "Tayinlanmagan" variant
          GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _selected == null
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selected == null ? cs.primary : cs.outlineVariant,
                  width: _selected == null ? 2 : 1,
                ),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: _selected == null
                      ? cs.primary
                      : cs.surfaceContainerHigh,
                  child: Icon(Icons.person_off_outlined,
                      size: 18,
                      color: _selected == null ? cs.onPrimary : cs.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(s.assignLater,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _selected == null
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant)),
                ),
                if (_selected == null)
                  Icon(Icons.check_circle, color: cs.primary),
              ]),
            ),
          ),

          // Tasdiqlash tugmasi
          FilledButton(
            onPressed: () {
              final driver = _selected != null
                  ? widget.drivers.firstWhere((d) => d.id == _selected)
                  : null;
              Navigator.pop(context,
                  (confirmed: true, driver: driver) as DriverDialogResult);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _selected != null
                  ? 'Tayyor — haydovchi tayinlandi'
                  : 'Tayyor — haydovchi keyinroq',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context,
                (confirmed: false, driver: null) as DriverDialogResult),
            child: Text(s.cancel),
          ),
        ],
      ),
    );
  }
}
