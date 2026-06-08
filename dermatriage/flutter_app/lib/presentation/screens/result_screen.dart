import 'package:flutter/material.dart';

/// Placeholder result screen — replace with the real triage result UI.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Triage Result')),
      body: const Center(child: Text('Result')),
    );
  }
}
