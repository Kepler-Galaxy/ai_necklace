import 'package:authing_sdk_v3/client.dart';
import 'package:authing_sdk_v3/result.dart';
import 'package:authing_sdk_v3/options/login_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:friend_private/backend/auth.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/providers/base_provider.dart';
import 'package:friend_private/services/notification_service.dart';
import 'package:friend_private/utils/alerts/app_snackbar.dart';
import 'package:friend_private/utils/analytics/mixpanel.dart';
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthenticationProvider extends BaseProvider {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  bool isCodeSent = false;

  void setIsCodeSentState(bool value) {
    isCodeSent = value;
    notifyListeners();
  }

  Future<void> onGoogleSignIn(Function() onSignIn) async {
    if (!loading) {
      setLoadingState(true);
      await signInWithGoogle();
      _signIn(onSignIn);
      setLoadingState(false);
    }
  }

  Future<void> onAppleSignIn(Function() onSignIn) async {
    if (!loading) {
      setLoadingState(true);
      await signInWithApple();
      _signIn(onSignIn);
      setLoadingState(false);
    }
  }

  Future<void> onVerificationCodeSignIn(
      BuildContext context, Function() onSignIn) async {
    if (!loading) {
      setLoadingState(true);

      String phone = phoneController.text.trim();
      String code = codeController.text.trim();

      if (phone.isEmpty || code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter both phone number and code.')),
        );
        setLoadingState(false);
        return;
      }

      try {
        LoginOptions opt = LoginOptions();
        opt.scope =
            "openid profile username email phone offline_access roles external_id extended_fields tenant_id";
        AuthResult result = await AuthClient.loginByPhoneCode(
          phone,
          code,
          null,
          opt,
        );
        debugPrint(result.data.toString());
        if (result.statusCode == 200 && result.user != null) {
          // 登录成功
          SharedPreferencesUtil().authToken = result.user!.accessToken;
          int nowTime = DateTime.now().millisecondsSinceEpoch;
          int expiresIn = result.data["expires_in"] * 1000;
          SharedPreferencesUtil().tokenExpirationTime = nowTime + expiresIn;

          AuthResult userInfo = await AuthClient.getCurrentUser();
          debugPrint(userInfo.data.toString());
          SharedPreferencesUtil().uid = userInfo.data["userId"] ?? "";
          SharedPreferencesUtil().email = userInfo.user!.email;

          onSignIn();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sign in: ${result.message}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setLoadingState(false);
      }
    }
  }

  Future<void> sendVerificationCode(BuildContext context) async {
    if (!loading) {
      setLoadingState(true);
      String phone = phoneController.text.trim();

      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a phone number.')),
        );
        setLoadingState(false);
        return;
      }

      try {
        AuthResult result = await AuthClient.sendSms(phone, "CHANNEL_LOGIN");
        if (result.statusCode == 200) {
          setIsCodeSentState(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification code sent.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send code: ${result.message}')),
          );
        }
      } catch (e) {
        setIsCodeSentState(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setLoadingState(false);
      }
    }
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

  // TODO: change to authing
  void _signIn(Function() onSignIn) async {
    String? token = await _getIdToken();

    if (token != null) {
      User user;
      try {
        user = FirebaseAuth.instance.currentUser!;
      } catch (e, stackTrace) {
        AppSnackbar.showSnackbarError(
            'Unexpected error signing in, Firebase error, please try again.');

        CrashReporting.reportHandledCrash(e, stackTrace,
            level: NonFatalExceptionLevel.error);
        return;
      }
      String newUid = user.uid;
      SharedPreferencesUtil().uid = newUid;
      MixpanelManager().identify();
      onSignIn();
    } else {
      AppSnackbar.showSnackbarError(
          'Unexpected error signing in, please try again');
    }
  }

  void openTermsOfService() {
    _launchUrl('https://basedhardware.com/terms');
  }

  void openPrivacyPolicy() {
    _launchUrl('https://basedhardware.com/privacy-policy');
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }
}
