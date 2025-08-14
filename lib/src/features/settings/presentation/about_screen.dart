import 'package:flutter/material.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';

/// Screen that displays information about the application.
class AboutScreen extends StatelessWidget {
  /// Creates an About screen widget.
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('${loc.app_name} - MIT License'),
      ),
    );
  }
}
