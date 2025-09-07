// Manual test to verify localization works
// Run this with: flutter run lib/manual_test.dart

import 'package:flutter/material.dart';
import 'main.dart';

void main() {
  runApp(const ManualTestApp());
}

class ManualTestApp extends StatelessWidget {
  const ManualTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Localization Manual Test'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Manual Test - Tap to launch the School Bus App'),
              SizedBox(height: 20),
              LaunchButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class LaunchButton extends StatelessWidget {
  const LaunchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SchoolBusApp(),
          ),
        );
      },
      child: const Text('Launch School Bus App'),
    );
  }
}