import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/strings.dart';
import '../../services/api_service.dart';
import '../../widgets/paginated_list.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.manageUsers),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.workers),
            Tab(text: s.drivers),
            Tab(text: s.upakovchikLabel),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: Text(s.add),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadUsers(),
            child: TabBarView(
              controller: _tabController,
              children: [
                _UserList(users: provider.workers),
                _UserList(users: provider.drivers),
                _UserList(users: provider.upakovchilar),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String selectedRole = 'worker';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(S(context.watch<ThemeProvider>().language).newUser),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: S(context.read<ThemeProvider>().language).nameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'worker', label: Text(S(context.read<ThemeProvider>().language).workerLabel2)),
                  ButtonSegment(value: 'driver', label: Text(S(context.read<ThemeProvider>().language).driverLabel2)),
                  ButtonSegment(value: 'upakovchik', label: Text(S(context.read<ThemeProvider>().language).upakovchikLabel)),
                ],
                selected: {selectedRole},
                onSelectionChanged: (v) =>
                    setDialogState(() => selectedRole = v.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(S(context.read<ThemeProvider>().language).cancelAction),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  final provider = context.read<UserProvider>();
                  final result = await provider.createUser(name, selectedRole);
                  if (context.mounted) {
                    _showCredentialsDialog(context, result);
                  }
                } catch (e) {
                  if (context.mounted) {
                    final s = S(context.read<ThemeProvider>().language);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${s.error}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(S(context.read<ThemeProvider>().language).createUser),
            ),
          ],
        ),
      ),
    );
  }

  void _showCredentialsDialog(BuildContext context, Map<String, dynamic> user) {
    final s = S(context.read<ThemeProvider>().language);
    final login = user['login'] ?? '';
    final password = user['generatedPassword'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(s.userCreated),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.credentialsSaveNote,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _CredentialTile(label: s.nameLabel, value: user['name'] ?? ''),
            _CredentialTile(label: s.loginLabel2, value: login),
            _CredentialTile(label: s.passwordCopy, value: password),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: Text(s.copyAction),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: 'Login: $login\nParol: $password'),
              );
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(s.copiedMsg)));
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.close),
          ),
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final String label;
  final String value;
  const _CredentialTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<UserModel> users;
  const _UserList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(
        child: Text(
          'Foydalanuvchilar mavjud emas',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return PaginatedList<UserModel>(
      items: users,
      pageSize: 20,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemBuilder: (ctx, user, _) => _UserCard(user: user),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = user.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? theme.colorScheme.primaryContainer
              : Colors.grey.shade200,
          child: Text(
            user.name[0],
            style: TextStyle(
              color: isActive
                  ? theme.colorScheme.onPrimaryContainer
                  : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '@${user.login}',
          style: TextStyle(
            color: isActive ? theme.colorScheme.onSurfaceVariant : Colors.grey,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isActive ? 'Faol' : 'Nofarol',
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.key_outlined, color: Colors.orange),
              tooltip: 'Login/Parolni ko\'rish',
              onPressed: () => _showPassword(context, user),
            ),
            IconButton(
              icon: Icon(
                isActive ? Icons.person_off_outlined : Icons.person_outlined,
                color: isActive ? Colors.red : Colors.green,
              ),
              tooltip: isActive ? 'Bloklash' : 'Faollashtirish',
              onPressed: () => _toggleUser(context, user),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPassword(BuildContext context, UserModel user) async {
    final s = S(context.read<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    bool loading = true;
    String login = user.login;
    String password = '...';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          if (loading) {
            context
                .read<ApiService>()
                .getUserPassword(user.id)
                .then((data) {
                  if (ctx.mounted) {
                    setState(() {
                      login = data['login'] ?? user.login;
                      password = data['password'] ?? '—';
                      loading = false;
                    });
                  }
                })
                .catchError((_) {
                  if (ctx.mounted) {
                    setState(() {
                      password = 'Xatolik';
                      loading = false;
                    });
                  }
                });
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.key_outlined, color: Colors.orange),
                const SizedBox(width: 8),
                Text(user.name, style: const TextStyle(fontSize: 16)),
              ],
            ),
            content: loading
                ? const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CredRow('Login', login, cs),
                      const SizedBox(height: 10),
                      _CredRow('Parol', password, cs),
                    ],
                  ),
            actions: [
              if (!loading)
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(s.copied),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: 'Login: $login\nParol: $password'),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.copied),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.close),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleUser(BuildContext context, UserModel user) async {
    final s = S(context.read<ThemeProvider>().language);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          user.isActive
              ? s.blockUser
              : s.activateUser,
        ),
        content: Text(
          user.isActive
              ? '${user.name}${s.blockConfirm}'
              : '${user.name}${s.activateConfirm}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? s.block : s.activate),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final provider = context.read<UserProvider>();
        if (user.isActive) {
          await provider.deactivateUser(user.id);
        } else {
          await provider.activateUser(user.id);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${s.error}: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

class _CredRow extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;
  const _CredRow(this.label, this.value, this.cs);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    ),
  );
}
