import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/shop_screen.dart';

void main() {
  runApp(const NaturallyYoursApp());
}

class NaturallyYoursApp extends StatelessWidget {
  const NaturallyYoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naturally Yours',
      debugShowCheckedModeBanner: false,
      theme: NYTheme.light(),
      darkTheme: NYTheme.dark(),
      themeMode: ThemeMode.system, // follows the device's light/dark setting
      home: const RootShell(),
    );
  }
}

/// Bottom-tab shell. Shop is wired to the live API; the other tabs are
/// placeholders we'll fill in as we port Home/Cart/Favorites/Account.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    ShopScreen(),
    _Placeholder('Cart'),
    _Placeholder('Favorites'),
    _Placeholder('Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title — coming soon', style: const TextStyle(color: Colors.grey)),
    );
  }
}
