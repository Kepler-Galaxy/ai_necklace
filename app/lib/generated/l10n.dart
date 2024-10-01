// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `hello`
  String get hello {
    return Intl.message(
      'hello',
      name: 'hello',
      desc: '',
      args: [],
    );
  }

  /// `Memories`
  String get Memories {
    return Intl.message(
      'Memories',
      name: 'Memories',
      desc: '',
      args: [],
    );
  }

  /// `Diary`
  String get Diary {
    return Intl.message(
      'Diary',
      name: 'Diary',
      desc: '',
      args: [],
    );
  }

  /// `Chat`
  String get Chat {
    return Intl.message(
      'Chat',
      name: 'Chat',
      desc: '',
      args: [],
    );
  }

  /// `Creating Memory`
  String get CreatingMemory {
    return Intl.message(
      'Creating Memory',
      name: 'CreatingMemory',
      desc: '',
      args: [],
    );
  }

  /// `Import Article`
  String get ImportArticle {
    return Intl.message(
      'Import Article',
      name: 'ImportArticle',
      desc: '',
      args: [],
    );
  }

  /// `Stop Recording`
  String get StopRecording {
    return Intl.message(
      'Stop Recording',
      name: 'StopRecording',
      desc: '',
      args: [],
    );
  }

  /// `Try With Phone Mic`
  String get TryWithPhoneMic {
    return Intl.message(
      'Try With Phone Mic',
      name: 'TryWithPhoneMic',
      desc: '',
      args: [],
    );
  }

  /// `No device found`
  String get NoDeviceFound {
    return Intl.message(
      'No device found',
      name: 'NoDeviceFound',
      desc: '',
      args: [],
    );
  }

  /// `Article Link: WeChat Article or Others`
  String get ArticleLinkWeChatArticleorOthers {
    return Intl.message(
      'Article Link: WeChat Article or Others',
      name: 'ArticleLinkWeChatArticleorOthers',
      desc: '',
      args: [],
    );
  }

  /// `Paste article link here`
  String get PasteArticleLinkHere {
    return Intl.message(
      'Paste article link here',
      name: 'PasteArticleLinkHere',
      desc: '',
      args: [],
    );
  }

  /// `Create Memory`
  String get CreateMemory {
    return Intl.message(
      'Create Memory',
      name: 'CreateMemory',
      desc: '',
      args: [],
    );
  }

  /// `Connect Your Audio Fairy`
  String get ConnectYourKstar {
    return Intl.message(
      'Connect Your Audio Fairy',
      name: 'ConnectYourKstar',
      desc: '',
      args: [],
    );
  }

  /// `Searching for devices...`
  String get SearchingForDevices {
    return Intl.message(
      'Searching for devices...',
      name: 'SearchingForDevices',
      desc: '',
      args: [],
    );
  }

  /// `Limited Capabilities`
  String get LimitedCapabilities {
    return Intl.message(
      'Limited Capabilities',
      name: 'LimitedCapabilities',
      desc: '',
      args: [],
    );
  }

  /// `Recording with your phone microphone has a few limitations, including but not limited to: speaker profiles, background reliability.`
  String get DescriptionOfRecordingWithPhoneMicrophone {
    return Intl.message(
      'Recording with your phone microphone has a few limitations, including but not limited to: speaker profiles, background reliability.',
      name: 'DescriptionOfRecordingWithPhoneMicrophone',
      desc: '',
      args: [],
    );
  }

  /// `Ok, I understand`
  String get OkIUnderstand {
    return Intl.message(
      'Ok, I understand',
      name: 'OkIUnderstand',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get Cancel {
    return Intl.message(
      'Cancel',
      name: 'Cancel',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(
          languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
