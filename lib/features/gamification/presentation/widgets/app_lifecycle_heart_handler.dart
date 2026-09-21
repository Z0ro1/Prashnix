import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/heart_economy_provider.dart';

class AppLifecycleHeartHandler extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleHeartHandler({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleHeartHandler> createState() => _AppLifecycleHeartHandlerState();
}

class _AppLifecycleHeartHandlerState extends ConsumerState<AppLifecycleHeartHandler> with WidgetsBindingObserver {
  // In a real app, this should be fetched from SQLite ProgressRepository on boot
  DateTime _lastRegenTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateHearts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateHearts();
    }
  }

  void _evaluateHearts() {
    // Trigger evaluation on provider
    ref.read(heartEconomyProvider.notifier).evaluateRegeneration(_lastRegenTime);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
