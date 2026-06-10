// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/strings.dart';
import '../../utils/phone_utils.dart';

class OrderFormScreen extends StatefulWidget {
  final OrderModel? order;
  const OrderFormScreen({super.key, this.order});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Olib ketish sanasi avtomatik — hozirgi vaqt
  final DateTime _pickupDate = DateTime.now();

  String? _selectedDriverId;
  List<UserModel> _drivers = [];

  bool _isSaving = false;
  bool get _isEdit => widget.order != null;

  @override
  void initState() {
    super.initState();
    _loadUsers();

    if (_isEdit) {
      final o = widget.order!;
      _nameCtrl.text = o.customerName;
      _phoneCtrl.text = formatPhone(o.phone);
      _addressCtrl.text = o.address;
      _notesCtrl.text = o.notes ?? '';
      _selectedDriverId = o.assignedDriverId;
    }
  }

  Future<void> _loadUsers() async {
    final up = context.read<UserProvider>();
    if (up.drivers.isEmpty) await up.loadUsers();
    if (mounted) {
      setState(() {
        _drivers = up.activeDrivers;
      });
    }
  }

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
      if (_isEdit) {
        await provider.updateOrder(widget.order!.copyWith(
          customerName: _nameCtrl.text.trim(),
          phone: rawPhone(_phoneCtrl.text),
          address: _addressCtrl.text.trim(),
          pickupDate: _pickupDate,
          deliveryDate: _pickupDate, // yetkazish vaqti tayyor bo'lganda belgilanadi
          assignedDriverId: _selectedDriverId,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ));
      } else {
        await provider.addOrder(
          customerName: _nameCtrl.text.trim(),
          phone: rawPhone(_phoneCtrl.text),
          address: _addressCtrl.text.trim(),
          carpetCount: 0,
          carpetTypes: '',
          pickupDate: _pickupDate,
          deliveryDate: _pickupDate,
          assignedDriverId: _selectedDriverId,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.editOrder : s.newOrder),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [

            // ─── Mijoz ────────────────────────────────────────────────────
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

            // ─── Izoh ────────────────────────────────────────────────────
            _SectionCard(
              title: s.carpetTypeOrNote,
              icon: Icons.layers_outlined,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: theme.colorScheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.carpetSizeInfo,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: _dec(s.carpetTypeHint, Icons.notes_outlined),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ─── Tayinlash ───────────────────────────────────────────────
            _SectionCard(
              title: s.assignInfo,
              icon: Icons.assignment_ind_outlined,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedDriverId,
                  decoration: _dec(s.driver, Icons.local_shipping_outlined),
                  hint: Text(s.selectDriver),
                  items: [
                    DropdownMenuItem(value: null, child: Text(s.notAssignedDash)),
                    ..._drivers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedDriverId = v),
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
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _isEdit ? s.save : s.addOrder,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

// ─── Widgets ────────────────────────────────────────────────────────────────────

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
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 14)),
            ]),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

