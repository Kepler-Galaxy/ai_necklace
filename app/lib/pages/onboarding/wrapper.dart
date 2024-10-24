import 'dart:math';

import 'package:flutter/material.dart';
import 'package:foxxy_package/backend/auth.dart';
import 'package:foxxy_package/backend/preferences.dart';
import 'package:foxxy_package/backend/schema/bt_device.dart';
import 'package:foxxy_package/pages/home/page.dart';
import 'package:foxxy_package/pages/onboarding/auth.dart';
import 'package:foxxy_package/pages/onboarding/find_device/page.dart';
import 'package:foxxy_package/pages/onboarding/memory_created_widget.dart';
import 'package:foxxy_package/pages/onboarding/name/name_widget.dart';
import 'package:foxxy_package/pages/onboarding/permissions/permissions_widget.dart';
import 'package:foxxy_package/pages/onboarding/speech_profile_widget.dart';
import 'package:foxxy_package/pages/onboarding/welcome/page.dart';
import 'package:foxxy_package/providers/home_provider.dart';
import 'package:foxxy_package/providers/onboarding_provider.dart';
import 'package:foxxy_package/providers/speech_profile_provider.dart';
import 'package:foxxy_package/services/services.dart';
import 'package:foxxy_package/utils/analytics/mixpanel.dart';
import 'package:foxxy_package/utils/other/temp.dart';
import 'package:provider/provider.dart';
import 'package:foxxy_package/generated/l10n.dart';
import 'package:foxxy_package/widgets/auth_image_widget.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper>
    with TickerProviderStateMixin {
  TabController? _controller;
  bool hasSpeechProfile = SharedPreferencesUtil().hasSpeakerProfile;

  @override
  void initState() {
    //TODO: Change from tab controller to default controller and use provider (part of instabug cleanup) @mdmohsin7
    // _controller = TabController(length: hasSpeechProfile ? 5 : 7, vsync: this);
    _controller = TabController(length: 5, vsync: this);
    _controller!.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (isSignedInAuthing()) {
        // && !SharedPreferencesUtil().onboardingCompleted
        context.read<HomeProvider>().setupHasSpeakerProfile();
        _goNext();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  _goNext() {
    if (_controller!.index < _controller!.length - 1) {
      _controller!.animateTo(_controller!.index + 1);
    } else {
      routeToPage(context, const HomePageWrapper(), replace: true);
    }
    // _controller!.animateTo(_controller!.index + 1);
  }

  // TODO: use connection directly
  Future<BleAudioCodec> _getAudioCodec(String deviceId) async {
    var connection =
        await ServiceManager.instance().device.ensureConnection(deviceId);
    if (connection == null) {
      return BleAudioCodec.pcm8;
    }
    return connection.getAudioCodec();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      // TODO: if connected already, stop animation and display battery
      AuthComponent(
        onSignIn: () {
          MixpanelManager().onboardingStepCompleted('Auth');
          context.read<HomeProvider>().setupHasSpeakerProfile();
          if (SharedPreferencesUtil().onboardingCompleted) {
            // previous users
            // Not needed anymore, because AuthProvider already does this
            // routeToPage(context, const HomePageWrapper(), replace: true);
          } else {
            _goNext();
          }
        },
      ),
      NameWidget(goNext: () {
        _goNext();
        MixpanelManager().onboardingStepCompleted('Name');
      }),
      PermissionsWidget(
        goNext: () {
          _goNext();
          MixpanelManager().onboardingStepCompleted('Permissions');
        },
      ),
      WelcomePage(
        goNext: () {
          _goNext();
          MixpanelManager().onboardingStepCompleted('Welcome');
        },
      ),
      FindDevicesPage(
        isFromOnboarding: true,
        onSkip: () {
          routeToPage(context, const HomePageWrapper(), replace: true);
        },
        goNext: () async {
          var provider = context.read<OnboardingProvider>();
          if (context.read<HomeProvider>().hasSpeakerProfile) {
            // previous users
            routeToPage(context, const HomePageWrapper(), replace: true);
          } else {
            if (provider.deviceId.isEmpty) {
              _goNext();
            } else {
              var codec = await _getAudioCodec(provider.deviceId);
              if (codec == BleAudioCodec.opus) {
                _goNext();
              } else {
                routeToPage(context, const HomePageWrapper(), replace: true);
              }
            }
          }

          MixpanelManager().onboardingStepCompleted('Find Devices');
        },
      ),
    ];

    // if (!hasSpeechProfile) {
    //   pages.addAll([
    //     SpeechProfileWidget(
    //       goNext: () {
    //         if (context.read<SpeechProfileProvider>().memory == null) {
    //           routeToPage(context, const HomePageWrapper(), replace: true);
    //         } else {
    //           _goNext();
    //         }
    //         MixpanelManager().onboardingStepCompleted('Speech Profile');
    //       },
    //       onSkip: () {
    //         routeToPage(context, const HomePageWrapper(), replace: true);
    //       },
    //     ),
    //     MemoryCreatedWidget(
    //       goNext: () {
    //         // _goNext();
    //         MixpanelManager().onboardingStepCompleted('Memory Created');
    //       },
    //     ),
    //   ]);
    // }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    AuthImageWidget(),
                    _controller!.index == 6 || _controller!.index == 7
                        ? const SizedBox()
                        : Center(
                            child: Text(
                              S.current.AppName,
                              style: TextStyle(
                                  color: Colors.grey.shade200,
                                  fontSize: _controller!.index ==
                                          _controller!.length - 1
                                      ? 28
                                      : 40,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                    const SizedBox(height: 24),
                    [-1, 5, 6, 7].contains(_controller?.index)
                        ? const SizedBox(
                            height: 0,
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              S.current.OneWordIntro,
                              style: TextStyle(
                                  color: Colors.grey.shade300, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                    SizedBox(
                      height: (_controller!.index == 5 ||
                              _controller!.index == 6 ||
                              _controller!.index == 7)
                          ? max(MediaQuery.of(context).size.height - 500 - 10,
                              maxHeightWithTextScale(context))
                          : max(MediaQuery.of(context).size.height - 500 - 60,
                              maxHeightWithTextScale(context)),
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.sizeOf(context).height <= 700
                                ? 10
                                : 64),
                        child: TabBarView(
                          controller: _controller,
                          physics: const NeverScrollableScrollPhysics(),
                          children: pages,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_controller!.index == 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 40, 16, 0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: () {
                        if (_controller!.index == 2) {
                          _controller!.animateTo(_controller!.index + 1);
                        } else {
                          routeToPage(context, const HomePageWrapper(),
                              replace: true);
                        }
                      },
                      child: Text(
                        S.current.Skip,
                        style: TextStyle(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
              if (_controller!.index > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 40, 0, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: TextButton(
                      onPressed: () {
                        _controller!.animateTo(_controller!.index - 1);
                      },
                      child: Text(
                        'Back',
                        style: TextStyle(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
              if (_controller!.index != 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _controller!.length -
                          1, // Exclude the Auth page from the count
                      (index) {
                        // Calculate the adjusted index
                        int adjustedIndex = index + 1;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width:
                              adjustedIndex == _controller!.index ? 12.0 : 8.0,
                          height:
                              adjustedIndex == _controller!.index ? 12.0 : 8.0,
                          decoration: BoxDecoration(
                            color: adjustedIndex <= _controller!.index
                                ? Theme.of(context).colorScheme.secondary
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

double maxHeightWithTextScale(BuildContext context) {
  double textScaleFactor = MediaQuery.of(context).textScaleFactor;
  if (textScaleFactor > 1.0) {
    return 455;
  } else {
    return 355;
  }
}
