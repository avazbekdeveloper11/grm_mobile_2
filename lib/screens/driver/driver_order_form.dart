// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/strings.dart';
import '../../utils/phone_utils.dart';

class DriverOrderForm extends StatefulWidget {
  const DriverOrderForm({super.key});

  @override
  State<DriverOrderForm> createState() => _DriverOrderFormState();
}

class _DriverOrderFormState extends State<DriverOrderForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final provider = context.read<OrderProvider>();
    try {
      await provider.addOrder(
        customerName: _nameCtrl.text.trim(),
        phone: rawPhone(_phoneCtrl.text),
        address: _addressCtrl.text.trim(),
        carpetCount: 0,
        carpetTypes: '',
        pickupDate: DateTime.now(),
        deliveryDate: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        final s = S(context.read<ThemeProvider>().language);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.newOrder),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // ─── Mijoz ma'lumotlari ───────────────────────────────────────
            _SectionCard(
              title: s.customerInfo,
              icon: Icons.person_outline,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _dec(s.customerName, Icons.person_outline),
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? s.enterName : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: _dec(s.phone, Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.enterPhone;
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 11) return s.fullPhoneNumber;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: _dec(s.address, Icons.location_on_outlined),
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  validator: (v) => v!.isEmpty ? s.enterAddress : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Izoh ─────────────────────────────────────────────────────
            _SectionCard(
              title: s.carpetTypeOrNote,
              icon: Icons.notes_outlined,
              children: [
                TextFormField(
                  controller: _notesCtrl,
                  decoration: _dec(s.carpetTypeHint, Icons.notes_outlined),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    s.addOrder,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      );
}

// ─── Section card widget ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ]),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
