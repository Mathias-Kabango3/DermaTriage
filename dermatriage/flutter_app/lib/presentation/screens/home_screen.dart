import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Placeholder home screen — replace with the real dashboard UI.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Center(child: Text('Home')),
    );
  }
}
