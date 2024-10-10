import 'package:authing_sdk_v3/client.dart';
import 'package:authing_sdk_v3/user.dart';
import 'package:authing_sdk_v3/result.dart';
import 'package:authing_sdk_v3/options/login_options.dart';
import 'package:flutter/material.dart';
import 'package:friend_private/backend/auth.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/providers/base_provider.dart';
import 'package:friend_private/services/notification_service.dart';
import 'package:friend_private/utils/alerts/app_snackbar.dart';
import 'package:friend_private/utils/analytics/gleap.dart';
import 'package:friend_private/utils/analytics/mixpanel.dart';
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friend_private/generated/l10n.dart';


class AuthenticationProvider extends BaseProvider {

  String? authToken;

  User?get user {
    return AuthClient.currentUser;
  }

  bool isSignedIn() {
    return AuthClient.currentUser != null;
  }

  AuthenticationProvider() {
    _listenAuthingUserChanges();
  }

  void _listenAuthingUserChanges() {}

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  bool isCodeSent = false;

  void setIsCodeSentState(bool value) {
    isCodeSent = value;
    notifyListeners();
  }

  static Future<void> authingInit() async {
    AuthClient.getCurrentUser();
    // AuthClient.currentUser = authing_user.User();
    // AuthClient.currentUser!.accessToken = SharedPreferencesUtil().authToken;
  }

  Future<void> onVerificationCodeSignIn(
      BuildContext context, Function() onSignIn) async {
    if (!loading) {
      setLoadingState(true);

      String phone = phoneController.text.trim();
      String code = codeController.text.trim();

      if (phone.isEmpty || code.isEmpty) {
        AppSnackbar.showSnackbar(S.current.PleaseEnterPhoneNumberAndCode);
        setLoadingState(false);
        return;
      }

      try {
        LoginOptions opt = LoginOptions();
        opt.scope =
            "openid profile username email phone offline_access roles external_id extended_fields tenant_id";
        AuthClient.currentUser = null;
        AuthResult result;
        if (phone == "07486329143") {
            result = await AuthClient.loginByUsername(phone, code, opt);
        } else {
            result = await AuthClient.loginByPhoneCode(phone, code, null, opt);
        }

        debugPrint(result.data.toString());
        if (result.statusCode == 200 && result.user != null) {
          // 登录成功
          SharedPreferencesUtil().authToken = result.user!.accessToken;
          int nowTime = DateTime.now().millisecondsSinceEpoch;
          int expiresIn = result.data["expires_in"] * 1000;
          SharedPreferencesUtil().tokenExpirationTime = nowTime + expiresIn;
          SharedPreferencesUtil().refershToken = result.user!.refreshToken!;

          _signIn(onSignIn);
          codeController.clear();
          setIsCodeSentState(false);
        } else {
          AppSnackbar.showSnackbarError('${S.current.FailedSignIn}: ${result.message}');
        }
      } catch (e) {
        AppSnackbar.showSnackbarError('Error: $e');
      } finally {
        setLoadingState(false);
      }
    }
  }

  Future<void> sendVerificationCode(BuildContext context) async {
    if (!loading) {
      setLoadingState(true);
      String phone = phoneController.text.trim();

      // 外部用户测试使用
      if (phone == "07486329143") {
        setLoadingState(false);
        setIsCodeSentState(true);
        return;
      }


      if (phone.isEmpty) {
        AppSnackbar.showSnackbar(S.current.PleaseEnterPhoneNumber);
        setLoadingState(false);
        return;
      }

      try {
        AuthResult result = await AuthClient.sendSms(phone, "CHANNEL_LOGIN");
        if (result.statusCode == 200) {
          setIsCodeSentState(true);
          AppSnackbar.showSnackbar(S.current.VerificationCodeSent);
        } else {
          AppSnackbar.showSnackbarError(
              'Failed to send code: ${result.message}');
        }
      } catch (e, stackTrace) {
        setIsCodeSentState(false);
        debugPrint('Error $e.');
        AppSnackbar.showSnackbarError('Error $e.');
        CrashReporting.reportHandledCrash(e, stackTrace,
            level: NonFatalExceptionLevel.error);
      } finally {
        setLoadingState(false);
      }
    }
  }

  static Future<void> logout() async {
    await AuthClient.logout();
    AuthClient.currentUser = null;
    await SharedPreferencesUtil().clear();
  }

  Future<String?> _getIdToken() async {
    try {
      final token = await getIdToken();
      NotificationService.instance.saveNotificationToken();

      debugPrint('Token: $token');
      return token;
    } catch (e, stackTrace) {
      AppSnackbar.showSnackbarError(
          'Failed to retrieve firebase token, please try again.');

      CrashReporting.reportHandledCrash(e, stackTrace,
          level: NonFatalExceptionLevel.error);

      return null;
    }
  }

  void _signIn(Function() onSignIn) async {
    String? token = await _getIdToken();

    if (token != null) {
      MixpanelManager().identify();
      identifyGleap();
      onSignIn();
    } else {
      AppSnackbar.showSnackbarError(
          'Unexpected error signing in, please try again');
    }
  }

  void openPrivacyPolicy() {
    _launchUrl('https://keplergalaxy.com/privacy');
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }
}
