import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/cart_store.dart';
import '../services/favorites_store.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'contact_screen.dart';
import 'admin/admin_gate.dart';

/// Account tab: profile + sign out when logged in; sign-in prompt otherwise.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        if (user != null) ...[
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: NYTheme.pink.withOpacity(0.15),
                child: Text(user.initials,
                    style: const TextStyle(
                        color: NYTheme.pink, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    Text(user.email, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              await context.read<AuthService>().logout();
              context.read<CartStore>().reset();
              context.read<FavoritesStore>().reset();
            },
          ),
        ] else ...[
          const Text('You are browsing as a guest',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Sign in to track orders and save favorites.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NYTheme.pink,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Sign In / Create Account'),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.forum_outlined),
          title: const Text('Contact Us'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ContactScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Staff Login'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminGate()),
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Naturally Yours Beauty Supply'),
          subtitle: Text('v1.0'),
        ),
      ],
    );
  }
}
