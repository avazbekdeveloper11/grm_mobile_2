// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../l10n/strings.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/fcm_service_flutter.dart';
import 'admin/admin_home.dart';
import 'worker/worker_home.dart';
import 'driver/driver_home.dart';
import 'upakovchik/upakovchik_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final auth = context.read<AuthProvider>();
    final err = await auth.login(_loginCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    // Android ga: bu login muvaffaqiyatli bo'ldi — saqlash taklif qil
    TextInput.finishAutofillContext(shouldSave: true);

    final api = context.read<ApiService>();
    await Future.wait([
      context.read<OrderProvider>().loadOrders(),
      context.read<UserProvider>().loadUsers(),
    ]);
    await _requestNotificationPermission(api);
    if (mounted) _navigateToHome(auth.currentUser!);
  }

  Future<void> _requestNotificationPermission(ApiService api) async {
    await FcmService.init(api);
  }

  void _navigateToHome(UserModel user) {
    Widget home;
    switch (user.role) {
      case UserRole.admin:
        home = const AdminHome();
        break;
      case UserRole.worker:
        home = const WorkerHome();
        break;
      case UserRole.driver:
        home = const DriverHome();
        break;
      case UserRole.upakovchik:
        home = const UpakovchikHome();
        break;
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => home));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;
    final s = S(context.watch<ThemeProvider>().language);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0D1B2A), const Color(0xFF1A2F45)]
                    : [cs.primary, cs.primary.withValues(alpha: 0.85)],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.52,
              decoration: BoxDecoration(
                color: isDark ? cs.surface : const Color(0xFFF5F7FA),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          // Til tugmasi
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _LangToggle(),
          ),

          // Kontent
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: 44,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.appTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.managementSystem,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 44),

                    // Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? cs.surfaceContainerHigh : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                s.login,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A2E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Login field
                              TextFormField(
                                controller: _loginCtrl,
                                autofillHints: const [AutofillHints.username],
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: s.loginLabel,
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    size: 20,
                                  ),
                                ),
                                validator: (v) => v!.isEmpty
                                    ? '${s.loginLabel} kiriting'
                                    : null,
                              ),
                              const SizedBox(height: 14),

                              // Password field
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: s.passwordLabel,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => v!.isEmpty
                                    ? '${s.passwordLabel} kiriting'
                                    : null,
                              ),

                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: cs.onErrorContainer,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: cs.onErrorContainer,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: isLoading ? null : _login,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        s.loginButton,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isCyr = tp.language == AppLanguage.uzCyrillic;
    return GestureDetector(
      onTap: () =>
          tp.setLanguage(isCyr ? AppLanguage.uzLatin : AppLanguage.uzCyrillic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Text(
          isCyr ? "O'zbek" : "Ўзбек",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
