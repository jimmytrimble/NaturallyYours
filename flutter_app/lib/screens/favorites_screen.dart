import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/favorites_store.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'shop_screen.dart'; // ProductCard

/// Wishlist tab (signed-in users only).
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthService>().isAuthenticated) {
        context.read<FavoritesStore>().refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final store = context.watch<FavoritesStore>();

    if (!auth.isAuthenticated) return _signInPrompt(context);
    if (store.loading && store.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.isEmpty) return _empty();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Favorites', style: NYTheme.screenTitle),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: store.refresh,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              itemCount: store.favorites.length,
              itemBuilder: (_, i) => ProductCard(product: store.favorites[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _heart(),
            const SizedBox(height: 12),
            const Text('No Favorites Yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Tap the heart on any product to save it here.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );

  Widget _signInPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _heart(),
              const SizedBox(height: 12),
              const Text('Save Your Favorites',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Sign in to keep a wishlist of products you love.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: NYTheme.pink),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Sign In / Create Account'),
              ),
            ],
          ),
        ),
      );

  Widget _heart() => CircleAvatar(
        radius: 42,
        backgroundColor: NYTheme.pink.withOpacity(0.12),
        child: const Icon(Icons.favorite, color: NYTheme.pink, size: 34),
      );
}
