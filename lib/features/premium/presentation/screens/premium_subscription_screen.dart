import 'package:flutter/material.dart';

class PremiumSubscriptionScreen extends StatelessWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Plus'),
      ),
      body: const Center(
        child: Text('Premium Subscription Paywall Placeholder\n\n(Subscribe to remove ads and get infinite hearts)'),
      ),
    );
  }
}
