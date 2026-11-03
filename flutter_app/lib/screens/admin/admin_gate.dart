import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../models/admin_models.dart';
import '../../services/admin_service.dart';
import '../../theme.dart';
import 'admin_inventory.dart';
import 'admin_orders.dart';
import 'admin_inbox.dart';
import 'admin_vending.dart';

/// Entry point for the staff area: restores any admin session, then shows the
/// login screen or the dashboard.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _service = AdminService();
  AdminUser? _admin;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final admin = await _service.me();
    if (mounted) setState(() {
      _admin = admin;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_admin == null) {
      return _AdminLogin(service: _service, onLoggedIn: (a) => setState(() => _admin = a));
    }
    return AdminDashboard(
      service: _service,
      admin: _admin!,
      onLogout: () async {
        await _service.logout();
        if (mounted) setState(() => _admin = null);
      },
    );
  }
}

class _AdminLogin extends StatefulWidget {
  const _AdminLogin({required this.service, required this.onLoggedIn});
  final AdminService service;
  final void Function(AdminUser) onLoggedIn;

  @override
  State<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<_AdminLogin> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _busy = true; _error = null; });
    try {
      final admin = await widget.service.login(_email.text, _password.text);
      widget.onLoggedIn(admin);
    } catch (e) {
      setState(() => _error = e is ApiException ? e.message : 'Login failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Login')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.lock_outline, size: 56, color: NYTheme.pink),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NYTheme.pink, minimumSize: const Size.fromHeight(50)),
            onPressed: _busy ? null : _login,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Log In'),
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.service, required this.admin, required this.onLogout});
  final AdminService service;
  final AdminUser admin;
  final VoidCallback onLogout;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      AdminInventory(service: widget.service, admin: widget.admin),
      AdminOrders(service: widget.service),
      AdminInbox(service: widget.service),
      AdminVending(service: widget.service, admin: widget.admin),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') widget.onLogout();
              if (v == 'exit') Navigator.of(context).maybePop();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text('${widget.admin.name} · ${widget.admin.roleDisplay}')),
              const PopupMenuItem(value: 'logout', child: Text('Log Out')),
              const PopupMenuItem(value: 'exit', child: Text('Exit Admin')),
            ],
          ),
        ],
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.local_drink_outlined), label: 'Vending'),
        ],
      ),
    );
  }
}
