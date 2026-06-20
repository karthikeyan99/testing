import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'providers/sales_provider.dart';
import 'screens/home_shell.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SalesTrackerApp());
}

class SalesTrackerApp extends StatelessWidget {
  const SalesTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SalesProvider()..load()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()..load()),
      ],
      child: MaterialApp(
        title: 'Sales Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
