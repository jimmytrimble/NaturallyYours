import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/cart_store.dart';
import 'services/favorites_store.dart';
import 'screens/home_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/account_screen.dart';

void main() {
  runApp(const NaturallyYoursApp());
}

class NaturallyYoursApp extends StatelessWidget {
  const NaturallyYoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..restore()),
        ChangeNotifierProvider(create: (_) => CartStore()..refresh()),
        ChangeNotifierProvider(create: (_) => FavoritesStore()),
      ],
      child: MaterialApp(
        title: 'Naturally Yours',
        debugShowCheckedModeBanner: false,
        theme: NYTheme.light(),
        darkTheme: NYTheme.dark(),
        themeMode: ThemeMode.system,
        home: const RootShell(),
      ),
    );
  }
}

/// Bottom-tab shell. Home/Shop/Cart/Account are wired; Favorites is a placeholder.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    ShopScreen(),
    CartScreen(),
    FavoritesScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartStore>().itemCount;

    return Scaffold(
      // Cap content to a phone-like width so the layout stays correct on wide
      // desktop/web windows (and is unaffected on real phones).
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _tabs[_index],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
