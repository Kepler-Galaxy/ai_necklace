import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:foxxy_package/providers/home_provider.dart';
import 'package:foxxy_package/providers/onboarding_provider.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/widgets/dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

import 'found_devices.dart';

class FindDevicesPage extends StatefulWidget {
  final bool isFromOnboarding;
  final VoidCallback goNext;
  final VoidCallback? onSkip;
  final bool includeSkip;

  const FindDevicesPage(
      {super.key,
      required this.goNext,
      this.includeSkip = true,
      this.isFromOnboarding = false,
      this.onSkip});

  @override
  State<FindDevicesPage> createState() => _FindDevicesPageState();
}

class _FindDevicesPageState extends State<FindDevicesPage> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.isFromOnboarding) {
        context.read<HomeProvider>().setupHasSpeakerProfile();
      }
      _scanDevices();
    });
  }

  @override
  dispose() {
    // context.read<OnboardingProvider>().dispose();
    super.dispose();
  }

  Future<void> _scanDevices() async {
    Provider.of<OnboardingProvider>(context, listen: false).scanDevices(
      onShowDialog: () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => getDialog(
              context,
              () {
                Navigator.of(context).pop();
              },
              () {},
              'Enable Bluetooth',
              'Audio Foxxy needs Bluetooth to connect to your wearable. Please enable Bluetooth and try again.',
              singleButton: true,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FoundDevices(
              goNext: widget.goNext,
              isFromOnboarding: widget.isFromOnboarding,
            ),
            if (provider.deviceList.isEmpty && provider.enableInstructions)
              const SizedBox(height: 48),
            // if (provider.deviceList.isEmpty && provider.enableInstructions)
            //   ElevatedButton(
            //     onPressed: () => {},
            //     child: Container(
            //       width: double.infinity,
            //       height: 45,
            //       alignment: Alignment.center,
            //       child: const Text(
            //         'Contact Support?',
            //         style: TextStyle(
            //           fontWeight: FontWeight.w400,
            //           fontSize: 16,
            //           color: Colors.white,
            //           decoration: TextDecoration.underline,
            //         ),
            //       ),
            //     ),
            //   ),
            if (widget.includeSkip && provider.deviceList.isEmpty)
              ElevatedButton(
                onPressed: () {
                  if (widget.isFromOnboarding) {
                    widget.onSkip!();
                  } else {
                    widget.goNext();
                  }
                  MixpanelManager().useWithoutDeviceOnboardingFindDevices();
                },
                child: Container(
                  width: double.infinity,
                  height: 45,
                  alignment: Alignment.center,
                  child: Text(
                    S.current.ConnectLater,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.white,
                      // decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
