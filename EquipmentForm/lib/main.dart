import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/di.dart';
import 'app/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = AppLogger();

  FlutterError.onError = (details) {
    logger.error('Flutter framework error', error: details.exception, stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught platform error', error: error, stackTrace: stack);
    return true;
  };

  runZonedGuarded(
    () => runApp(
      ProviderScope(
        overrides: [appLoggerProvider.overrideWithValue(logger)],
        child: const EquipmentFormApp(),
      ),
    ),
    (error, stack) => logger.error('Uncaught zone error', error: error, stackTrace: stack),
  );
}

class EquipmentFormApp extends ConsumerWidget {
  const EquipmentFormApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Equipment Form MVP',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
