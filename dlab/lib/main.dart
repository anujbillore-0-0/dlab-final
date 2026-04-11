import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/provider/auth_providers.dart';

Future<void> main() async {
  final container = ProviderContainer();

  try {
    await bootstrap(container);
  } catch (e, st) {
    debugPrint('╔══ BOOTSTRAP ERROR ══');
    debugPrint('║ $e');
    debugPrint('║ $st');
    debugPrint('╚═════════════════════');
    // Still launch the app so the user sees *something* instead of a black screen.
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const DLabApp(),
    ),
  );
}

class DLabApp extends ConsumerStatefulWidget {
  const DLabApp({super.key});

  @override
  ConsumerState<DLabApp> createState() => _DLabAppState();
}

class _DLabAppState extends ConsumerState<DLabApp> {
  @override
  void initState() {
    super.initState();
    // Note: runs once. Keeps auth flow out of UI widgets.
    Future.microtask(() => ref.read(authStateProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'dLab',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
