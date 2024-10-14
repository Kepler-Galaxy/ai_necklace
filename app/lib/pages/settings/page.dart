import 'package:flutter/material.dart';
import 'package:foxxy_package/providers/auth_provider.dart';
import 'package:foxxy_package/providers/message_provider.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/main.dart';
import 'package:foxxy_package/pages/settings/profile.dart';
import 'package:foxxy_package/pages/settings/widgets.dart';
import 'package:foxxy_package/utils/other/temp.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:foxxy_package/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:foxxy_package/pages/facts/page.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';

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
                getItemAddOn2(
                  'What Foxxy learned about you 👀',
                  () {
                    routeToPage(context, const FactsPage());
                    MixpanelManager().pageOpened('Profile Facts');
                  },
                  icon: Icons.self_improvement,
                ),
                const SizedBox(height: 32),
                getItemAddOn2(
                  'Privacy Policy',
                  () =>
                      launchUrl(Uri.parse('https://keplergalaxy.com/privacy')),
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
                        await context
                            .read<AuthenticationProvider>()
                            .logout(context);
                        Navigator.of(context).pop();
                        await routeToPage(context, const DeciderWidget(),
                            replace: true);
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
                      //'Version: $version+$buildVersion',
                      'Version: $version',
                      style: const TextStyle(
                          color: Color.fromARGB(255, 150, 150, 150),
                          fontSize: 16),
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
