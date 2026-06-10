import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

typedef UpakovchikDialogResult = ({bool confirmed, UserModel? user});

Future<UpakovchikDialogResult> showSelectUpakovchikDialog(
  BuildContext context, {
  String? currentUpakovchikId,
}) async {
  final up = context.read<UserProvider>();
  if (up.activeUpakovchilar.isEmpty) await up.loadUsers();
  final upakovchilar = up.activeUpakovchilar;

  if (!context.mounted) return (confirmed: false, user: null);

  final result = await showModalBottomSheet<UpakovchikDialogResult>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    isScrollControlled: true,
    isDismissible: true,
    builder: (ctx) => _SelectUpakovchikSheet(
      upakovchilar: upakovchilar,
      currentUpakovchikId: currentUpakovchikId,
    ),
  );
  return result ?? (confirmed: false, user: null);
}

class _SelectUpakovchikSheet extends StatefulWidget {
  final List<UserModel> upakovchilar;
  final String? currentUpakovchikId;
  const _SelectUpakovchikSheet(
      {required this.upakovchilar, this.currentUpakovchikId});

  @override
  State<_SelectUpakovchikSheet> createState() => _SelectUpakovchikSheetState();
}

class _SelectUpakovchikSheetState extends State<_SelectUpakovchikSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentUpakovchikId;
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
          Row(children: [
            Icon(Icons.inventory_2_outlined, color: cs.primary),
            const SizedBox(width: 10),
            Text(s.selectUpakovchik,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface)),
          ]),
          const SizedBox(height: 4),
          Text(s.whoPackages,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),

          if (widget.upakovchilar.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                s.noActivePackers,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          ...widget.upakovchilar.map((u) {
            final isSelected = _selected == u.id;
            return GestureDetector(
              onTap: () => setState(() => _selected = u.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    child: Text(u.name[0],
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? cs.onPrimary
                                : cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(u.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isSelected
                                ? cs.onPrimaryContainer
                                : cs.onSurface)),
                  ),
                  if (isSelected) Icon(Icons.check_circle, color: cs.primary),
                ]),
              ),
            );
          }),

          GestureDetector(
            onTap: () => setState(() => _selected = null),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      color: _selected == null
                          ? cs.onPrimary
                          : cs.onSurfaceVariant),
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

          FilledButton(
            onPressed: () {
              final user = _selected != null
                  ? widget.upakovchilar.firstWhere((u) => u.id == _selected)
                  : null;
              Navigator.pop(context,
                  (confirmed: true, user: user) as UpakovchikDialogResult);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _selected != null
                  ? s.assignedPacker
                  : s.packerAssignLater,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
