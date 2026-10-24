import 'package:flutter/material.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
      ),
      body: const Center(
        child: Text('Daily Quests Placeholder\n\n(Complete tasks to earn Gems)'),
      ),
    );
  }
}
