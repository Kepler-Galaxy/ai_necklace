import 'package:friend_private/env/dev_env.dart';

abstract class Env {
  static late final EnvFields _instance;

  static void init([EnvFields? instance]) {
    _instance = instance ?? DevEnv() as EnvFields;
  }

  static String? get oneSignalAppId => _instance.oneSignalAppId;

  static String? get openAIAPIKey => _instance.openAIAPIKey;
  // static String? get openAIAPIKey => 'sk-proj-359BpHDgAm5zESDq5zlET3BlbkFJFj4s2MQ3e2Caq7l6evDR';

  static String? get instabugApiKey => _instance.instabugApiKey;

  static String? get mixpanelProjectToken => _instance.mixpanelProjectToken;

  // static String? get apiBaseUrl => _instance.apiBaseUrl;
  // static String? get apiBaseUrl => 'https://equal-magnetic-pheasant.ngrok-free.app/';
  static String? get apiBaseUrl => 'http://kstar.anoyer.cn:18080/';
  // static String? get apiBaseUrl => 'https://camel-lucky-reliably.ngrok-free.app/';

  static String? get growthbookApiKey => _instance.growthbookApiKey;

  static String? get googleMapsApiKey => _instance.googleMapsApiKey;

  static String? get authingUserPoolId => _instance.authingUserPoolId;

  static String? get authingAppId => _instance.authingAppId;

  static String? get supabaseUrl => _instance.supabaseUrl;

  static String? get supabaseAnonKey => _instance.supabaseAnonKey;
}

abstract class EnvFields {
  String? get oneSignalAppId;

  String? get openAIAPIKey;

  String? get instabugApiKey;

  String? get mixpanelProjectToken;

  String? get apiBaseUrl;

  String? get growthbookApiKey;

  String? get googleMapsApiKey;

  String? get authingUserPoolId;
  String? get authingAppId;
  String? get supabaseUrl;
  String? get supabaseAnonKey;
}
