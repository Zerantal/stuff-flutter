// lib/app/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'injection.dart';
import 'routing/app_router.dart';
import 'bootstrap.dart';
import 'theme.dart';

void main() {
  // Heavy init (logging, Hive, error handlers) happens in bootstrap().
  bootstrap(() => const MyApp());
}

// final _routerLog = Logger('AppRouter');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildGlobalProviders(dataService: essentialServices.dataService),
      child: MaterialApp.router(
        title: 'Stuff',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
