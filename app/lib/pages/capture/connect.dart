import 'package:flutter/material.dart';
import 'package:foxxy_package/pages/settings/device_settings.dart';
import 'package:foxxy_package/pages/home/page.dart';
import 'package:foxxy_package/pages/onboarding/find_device/page.dart';
import 'package:foxxy_package/utils/other/temp.dart';
import 'package:foxxy_package/widgets/device_widget.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

class ConnectDevicePage extends StatefulWidget {
  const ConnectDevicePage({super.key});

  @override
  State<ConnectDevicePage> createState() => _ConnectDevicePageState();
}

class _ConnectDevicePageState extends State<ConnectDevicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.current.ConnectYourAudioFairy),
          backgroundColor: Theme.of(context).colorScheme.primary,
          // actions: [
          //   IconButton(
          //     onPressed: () {
          //       Navigator.of(context).push(
          //         MaterialPageRoute(
          //           builder: (context) => const DeviceSettings(),
          //         ),
          //       );
          //     },
          //     icon: const Icon(Icons.settings),
          //   )
          // ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: ListView(
          children: [
            const DeviceAnimationWidget(),
            FindDevicesPage(
              isFromOnboarding: false,
              goNext: () {
                debugPrint('onConnected from FindDevicesPage');
                routeToPage(context, const HomePageWrapper(), replace: true);
              },
              includeSkip: false,
            )
          ],
        ));
  }
}
