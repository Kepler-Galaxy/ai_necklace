import 'package:flutter/material.dart';
import 'package:friend_private/providers/auth_provider.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/main.dart';
import 'package:friend_private/pages/settings/profile.dart';
import 'package:friend_private/pages/settings/widgets.dart';
import 'package:friend_private/utils/other/temp.dart';
import 'package:friend_private/widgets/dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:friend_private/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool optInAnalytics;
  late bool optInEmotionalFeedback;
  late bool devModeEnabled;
  String? version;
  String? buildVersion;

  @override
  void initState() {
    optInAnalytics = SharedPreferencesUtil().optInAnalytics;
    optInEmotionalFeedback = SharedPreferencesUtil().optInEmotionalFeedback;
    devModeEnabled = SharedPreferencesUtil().devModeEnabled;
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      version = packageInfo.version;
      buildVersion = packageInfo.buildNumber.toString();
      setState(() {});
    });
    super.initState();
  }

  bool loadingExportMemories = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: true,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            automaticallyImplyLeading: true,
            title: const Text('Settings'),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 32.0),
                getItemAddOn2(
                  'Profile',
                  () => routeToPage(context, const ProfilePage()),
                  icon: Icons.person,
                ),
                const SizedBox(height: 32),
                getItemAddOn2(
                  'Privacy Policy',
                  () => launchUrl(Uri.parse('https://keplergalaxy.com/privacy')),
                  icon: Icons.privacy_tip,
                ),
                getItemAddOn2(
                  'About Us',
                  () => launchUrl(Uri.parse('https://keplergalaxy.com')),
                  icon: Icons.info,
                ),
                const SizedBox(height: 32),
                getItemAddOn2(S.current.SignOut, () async {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return getDialog(context, () {
                        Navigator.of(context).pop();
                      }, () async {
                        await AuthenticationProvider.logout();
                        Navigator.of(context).pop();
                        await routeToPage(context, const DeciderWidget(), replace: true);
                      }, S.current.SignOut, S.current.AreYouSureSignOut);
                    },
                  );
                }, icon: Icons.logout),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Version: $version+$buildVersion',
                      style: const TextStyle(color: Color.fromARGB(255, 150, 150, 150), fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ));
  }
}