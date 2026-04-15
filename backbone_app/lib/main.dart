import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CoPilotNovaApp()));
}

class CoPilotNovaApp extends ConsumerStatefulWidget {
  const CoPilotNovaApp({super.key});

  @override
  ConsumerState<CoPilotNovaApp> createState() => _CoPilotNovaAppState();
}

class _CoPilotNovaAppState extends ConsumerState<CoPilotNovaApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CoPilot Nova',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
