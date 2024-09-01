import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:authing_sdk_v3/client.dart';
import 'package:authing_sdk_v3/result.dart';
import 'package:authing_sdk_v3/options/login_options.dart';
import 'package:flutter/material.dart';
import 'package:friend_private/utils/analytics/growthbook.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:friend_private/backend/auth.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/services/notification_service.dart';
import 'package:friend_private/utils/analytics/mixpanel.dart';
import 'package:instabug_flutter/instabug_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthComponent extends StatefulWidget {
  final VoidCallback onSignIn;

  const AuthComponent({super.key, required this.onSignIn});

  @override
  State<AuthComponent> createState() => _AuthComponentState();
}

class _AuthComponentState extends State<AuthComponent> {
  bool loading = false;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeSent = false;
  changeLoadingState() => setState(() => loading = !loading);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: loading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          // Add verification code input
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Verification Code',
              prefixIcon: Icon(Icons.sms),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _isCodeSent
              ? SignInButton(
                  Buttons.anonymous,
                  text: "登录/注册",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onPressed: loading ? () {} : _signInWithPhone,
                )
              : SignInButton(
                  Buttons.anonymous,
                  text: "获取验证码",
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onPressed: loading ? () {} : _sendVerificationCode,
                ),

          // !Platform.isIOS
          //     ? SignInButton(
          //         Buttons.google,
          //         padding:
          //             const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //         shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8)),
          //         onPressed: loading
          //             ? () {}
          //             : () async {
          //                 changeLoadingState();
          //                 await signInWithGoogle();
          //                 _signIn();
          //                 changeLoadingState();
          //               },
          //       )
          //     : SignInButton(
          //         Buttons.apple,
          //         padding:
          //             const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //         shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(8)),
          //         onPressed: loading
          //             ? () {}
          //             : () async {
          //                 changeLoadingState();
          //                 await signInWithApple();
          //                 _signIn();
          //                 changeLoadingState();
          //               },
          //       ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              children: [
                const TextSpan(text: 'By Signing in, you agree to our\n'),
                TextSpan(
                  text: 'Terms of service',
                  style: const TextStyle(decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap =
                        () => _launchUrl('https://basedhardware.com/terms'),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: const TextStyle(decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _launchUrl('https://basedhardware.com/privacy-policy');
                    },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Send verification code to the user's phone
  Future<void> _sendVerificationCode() async {
    changeLoadingState();

    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number.')),
      );
      changeLoadingState();
      return;
    }

    try {
      AuthResult result = await AuthClient.sendSms(phone, "CHANNEL_LOGIN");
      if (result.statusCode == 200) {
        setState(() {
          _isCodeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send code: ${result.message}')),
        );
      }
    } catch (e) {
      _isCodeSent = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      changeLoadingState();
    }
  }

  // Sign in or register with phone number and verification code
  Future<void> _signInWithPhone() async {
    changeLoadingState();

    String phone = _phoneController.text.trim();
    String code = _codeController.text.trim();

    if (phone.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both phone number and code.')),
      );
      changeLoadingState();
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
      print(result.data.toString());
      if (result.statusCode == 200 && result.user != null) {
        // 登录成功
        SharedPreferencesUtil().authToken = result.user!.accessToken;
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        int expires_in = result.data["expires_in"] * 1000;
        SharedPreferencesUtil().tokenExpirationTime = nowTime + expires_in;

        AuthResult userInfo = await AuthClient.getCurrentUser();
        print(userInfo.data.toString());
        SharedPreferencesUtil().uid = userInfo.data["userId"] ?? "";
        SharedPreferencesUtil().email = userInfo.user!.email;

        widget.onSignIn();
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
      changeLoadingState();
    }
  }

  void _signIn() async {
    String? token;
    try {
      token = await getIdToken();
      NotificationService.instance.saveNotificationToken();
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to retrieve firebase token, please try again.'),
      ));
      CrashReporting.reportHandledCrash(e, stackTrace,
          level: NonFatalExceptionLevel.error);
      return;
    }
    debugPrint('Token: $token');
    if (token != null) {
      User user;
      try {
        user = FirebaseAuth.instance.currentUser!;
      } catch (e, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Unexpected error signing in, Firebase error, please try again.'),
        ));
        CrashReporting.reportHandledCrash(e, stackTrace,
            level: NonFatalExceptionLevel.error);
        return;
      }
      String newUid = user.uid;
      SharedPreferencesUtil().uid = newUid;
      MixpanelManager().identify();
      widget.onSignIn();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unexpected error signing in, please try again.'),
      ));
    }
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch $url';
  }
}
