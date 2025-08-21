import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:teditox/src/core/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen that displays information about the application.
class AboutScreen extends StatefulWidget {
  /// Creates an About screen widget.
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).could_not_launch_url(url)),
        ),
      );
    }
  }

  void _showLicensePage() {
    showLicensePage(
      context: context,
      applicationName: AppLocalizations.of(context).app_name,
      applicationVersion: _packageInfo?.version ?? '0.1.0',
      applicationLegalese: '© 2025 TeditoX Contributors',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.about),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App name and version
            Text(
              loc.app_name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${loc.version}: ${_packageInfo?.version ?? '0.1.0'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              loc.app_description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // License link
            Card(
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(loc.view_license),
                subtitle: Text(loc.license),
                onTap: () => _launchUrl(
                  'https://raw.githubusercontent.com/zp1ke/teditox/main/LICENSE',
                ),
                trailing: const Icon(Icons.open_in_new),
              ),
            ),
            const SizedBox(height: 8),

            // Third-party licenses
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text(loc.view_third_party_licenses),
                subtitle: Text(loc.third_party_licenses),
                onTap: _showLicensePage,
                trailing: const Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 8),

            // Privacy Policy link (placeholder)
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: Text(loc.view_privacy_policy),
                subtitle: Text(loc.privacy_policy),
                onTap: () => _launchUrl(
                  'https://example.com/privacy',
                ), // TODO(dev): Replace with actual privacy policy URL
                trailing: const Icon(Icons.open_in_new),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
