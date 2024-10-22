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

  /// `Foxxy`
  String get AppName {
    return Intl.message(
      'Foxxy',
      name: 'AppName',
      desc: '',
      args: [],
    );
  }

  /// `Your personalized AI assistant that precisely reconstructs your work and life, and helps you get things done.`
  String get OneWordIntro {
    return Intl.message(
      'Your personalized AI assistant that precisely reconstructs your work and life, and helps you get things done.',
      name: 'OneWordIntro',
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

  /// `Speech Language`
  String get SpeechLanguage {
    return Intl.message(
      'Speech Language',
      name: 'SpeechLanguage',
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

  /// `Show Discarded`
  String get ShowDiscarded {
    return Intl.message(
      'Show Discarded',
      name: 'ShowDiscarded',
      desc: '',
      args: [],
    );
  }

  /// `Hide Discarded`
  String get HideDiscarded {
    return Intl.message(
      'Hide Discarded',
      name: 'HideDiscarded',
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

  /// `No valid URL found`
  String get NoValidURLFound {
    return Intl.message(
      'No valid URL found',
      name: 'NoValidURLFound',
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

  /// `Connect Your AudioFoxxy`
  String get ConnectYourAudioFairy {
    return Intl.message(
      'Connect Your AudioFoxxy',
      name: 'ConnectYourAudioFairy',
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

  /// `Select Another Day`
  String get SelectAnotherDay {
    return Intl.message(
      'Select Another Day',
      name: 'SelectAnotherDay',
      desc: '',
      args: [],
    );
  }

  /// `Memory Chains`
  String get MemoryChains {
    return Intl.message(
      'Memory Chains',
      name: 'MemoryChains',
      desc: '',
      args: [],
    );
  }

  /// `Memory Contents`
  String get MemoryContents {
    return Intl.message(
      'Memory Contents',
      name: 'MemoryContents',
      desc: '',
      args: [],
    );
  }

  /// `No connected memory for this date, wear AudioFoxxy or import articles to create more memories`
  String get DiaryNoConnectedMemory {
    return Intl.message(
      'No connected memory for this date, wear AudioFoxxy or import articles to create more memories',
      name: 'DiaryNoConnectedMemory',
      desc: '',
      args: [],
    );
  }

  /// `Connected Memories`
  String get DiaryMemoryConnectionText {
    return Intl.message(
      'Connected Memories',
      name: 'DiaryMemoryConnectionText',
      desc: '',
      args: [],
    );
  }

  /// `Memento`
  String get DiarySeparateMemoryText {
    return Intl.message(
      'Memento',
      name: 'DiarySeparateMemoryText',
      desc: '',
      args: [],
    );
  }

  /// `No diary entry for this date, wear AudioFoxxy to automatically record your diary`
  String get NoDiaryNote {
    return Intl.message(
      'No diary entry for this date, wear AudioFoxxy to automatically record your diary',
      name: 'NoDiaryNote',
      desc: '',
      args: [],
    );
  }

  /// `Explanation`
  String get ExplanationText {
    return Intl.message(
      'Explanation',
      name: 'ExplanationText',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get ExplanationClose {
    return Intl.message(
      'Close',
      name: 'ExplanationClose',
      desc: '',
      args: [],
    );
  }

  /// `Enable Plugins`
  String get EnablePlugins {
    return Intl.message(
      'Enable Plugins',
      name: 'EnablePlugins',
      desc: '',
      args: [],
    );
  }

  /// `Please check your internet connection and try again.`
  String get PleaseCheckInternetConnectionNote {
    return Intl.message(
      'Please check your internet connection and try again.',
      name: 'PleaseCheckInternetConnectionNote',
      desc: '',
      args: [],
    );
  }

  /// `Could not load Maps`
  String get CloudNotLoadMaps {
    return Intl.message(
      'Could not load Maps',
      name: 'CloudNotLoadMaps',
      desc: '',
      args: [],
    );
  }

  /// `Unable to fetch plugins`
  String get UnableFetchPlugins {
    return Intl.message(
      'Unable to fetch plugins',
      name: 'UnableFetchPlugins',
      desc: '',
      args: [],
    );
  }

  /// `Ask your AudioFoxxy anything`
  String get AskYourAudioFairyAnything {
    return Intl.message(
      'Ask your AudioFoxxy anything',
      name: 'AskYourAudioFairyAnything',
      desc: '',
      args: [],
    );
  }

  /// `Plugins`
  String get Plugins {
    return Intl.message(
      'Plugins',
      name: 'Plugins',
      desc: '',
      args: [],
    );
  }

  /// `Personalities`
  String get Personalities {
    return Intl.message(
      'Personalities',
      name: 'Personalities',
      desc: '',
      args: [],
    );
  }

  /// `External Apps`
  String get ExternalApps {
    return Intl.message(
      'External Apps',
      name: 'ExternalApps',
      desc: '',
      args: [],
    );
  }

  /// `Prompts`
  String get Prompts {
    return Intl.message(
      'Prompts',
      name: 'Prompts',
      desc: '',
      args: [],
    );
  }

  /// `Summary`
  String get Summary {
    return Intl.message(
      'Summary',
      name: 'Summary',
      desc: '',
      args: [],
    );
  }

  /// `Transcript`
  String get Transcript {
    return Intl.message(
      'Transcript',
      name: 'Transcript',
      desc: '',
      args: [],
    );
  }

  /// `Overview`
  String get Overview {
    return Intl.message(
      'Overview',
      name: 'Overview',
      desc: '',
      args: [],
    );
  }

  /// `Key Points`
  String get KeyPoints {
    return Intl.message(
      'Key Points',
      name: 'KeyPoints',
      desc: '',
      args: [],
    );
  }

  /// `No messages yet!`
  String get NoMessagesYet {
    return Intl.message(
      'No messages yet!',
      name: 'NoMessagesYet',
      desc: '',
      args: [],
    );
  }

  /// `Why don't you start a conversation?`
  String get WhyDontConversation {
    return Intl.message(
      'Why don\'t you start a conversation?',
      name: 'WhyDontConversation',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get Continue {
    return Intl.message(
      'Continue',
      name: 'Continue',
      desc: '',
      args: [],
    );
  }

  /// `Skip`
  String get Skip {
    return Intl.message(
      'Skip',
      name: 'Skip',
      desc: '',
      args: [],
    );
  }

  /// `Sign Out`
  String get SignOut {
    return Intl.message(
      'Sign Out',
      name: 'SignOut',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get Ok {
    return Intl.message(
      'OK',
      name: 'Ok',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to sign out?`
  String get AreYouSureSignOut {
    return Intl.message(
      'Are you sure you want to sign out?',
      name: 'AreYouSureSignOut',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get PhoneNumber {
    return Intl.message(
      'Phone Number',
      name: 'PhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Verification Code`
  String get VerificationCode {
    return Intl.message(
      'Verification Code',
      name: 'VerificationCode',
      desc: '',
      args: [],
    );
  }

  /// `Send Verification Code`
  String get SendVerificationCode {
    return Intl.message(
      'Send Verification Code',
      name: 'SendVerificationCode',
      desc: '',
      args: [],
    );
  }

  /// `Sign In / Sign Up`
  String get SignIn {
    return Intl.message(
      'Sign In / Sign Up',
      name: 'SignIn',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a phone number.`
  String get PleaseEnterPhoneNumber {
    return Intl.message(
      'Please enter a phone number.',
      name: 'PleaseEnterPhoneNumber',
      desc: '',
      args: [],
    );
  }

  /// `Verification code sent.`
  String get VerificationCodeSent {
    return Intl.message(
      'Verification code sent.',
      name: 'VerificationCodeSent',
      desc: '',
      args: [],
    );
  }

  /// `Failed to sign in`
  String get FailedSignIn {
    return Intl.message(
      'Failed to sign in',
      name: 'FailedSignIn',
      desc: '',
      args: [],
    );
  }

  /// `Please enter both phone number and code.`
  String get PleaseEnterPhoneNumberAndCode {
    return Intl.message(
      'Please enter both phone number and code.',
      name: 'PleaseEnterPhoneNumberAndCode',
      desc: '',
      args: [],
    );
  }

  /// `How should AudioFoxxy call you?`
  String get HowShouldAudioFairyCallYou {
    return Intl.message(
      'How should AudioFoxxy call you?',
      name: 'HowShouldAudioFairyCallYou',
      desc: '',
      args: [],
    );
  }

  /// `Allow AudioFoxxy to run in the background to improve stability`
  String get EnableBackgroundProcess {
    return Intl.message(
      'Allow AudioFoxxy to run in the background to improve stability',
      name: 'EnableBackgroundProcess',
      desc: '',
      args: [],
    );
  }

  /// `Enable background location access for Foxxy's full experience.`
  String get EnableBackgroundLocationAccess {
    return Intl.message(
      'Enable background location access for Foxxy\'s full experience.',
      name: 'EnableBackgroundLocationAccess',
      desc: '',
      args: [],
    );
  }

  /// `Enable notification access for Foxxy's full experience.`
  String get EnableNotificationAccess {
    return Intl.message(
      'Enable notification access for Foxxy\'s full experience.',
      name: 'EnableNotificationAccess',
      desc: '',
      args: [],
    );
  }

  /// `Connect My AudioFoxxy`
  String get ConnectMyAudioFairy {
    return Intl.message(
      'Connect My AudioFoxxy',
      name: 'ConnectMyAudioFairy',
      desc: '',
      args: [],
    );
  }

  /// `Connect Later`
  String get ConnectLater {
    return Intl.message(
      'Connect Later',
      name: 'ConnectLater',
      desc: '',
      args: [],
    );
  }

  /// `No memories generated yet.`
  String get NoMemoriesGeneratedYet {
    return Intl.message(
      'No memories generated yet.',
      name: 'NoMemoriesGeneratedYet',
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
