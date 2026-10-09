import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/day_screen.dart';
import 'screens/history_screen.dart';
import 'screens/products_screen.dart';
import 'screens/stats_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
  ));
  final store = Store();
  await store.load();
  runApp(EmberApp(store: store));
}

class EmberApp extends StatelessWidget {
  final Store store;
  const EmberApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ember',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Shell(store: store),
      );
}

class Shell extends StatefulWidget {
  final Store store;
  const Shell({super.key, required this.store});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Scaffold(
      body: IndexedStack(index: tab, children: [
        SafeArea(child: DayView(store: s, initialDate: today())),
        HistoryScreen(store: s),
        StatsScreen(store: s),
        ProductsScreen(store: s),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined),
              selectedIcon: Icon(Icons.local_fire_department),
              label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'Foods'),
        ],
      ),
    );
  }
}
