import 'dart:io';

import 'package:authing_sdk_v3/client.dart';
import 'package:authing_sdk_v3/result.dart';
import 'package:authing_sdk_v3/options/login_options.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:friend_private/utils/analytics/growthbook.dart';
import 'package:friend_private/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:friend_private/generated/l10n.dart';

class AuthComponent extends StatefulWidget {
  final VoidCallback onSignIn;

  const AuthComponent({super.key, required this.onSignIn});

  @override
  State<AuthComponent> createState() => _AuthComponentState();
}

class _AuthComponentState extends State<AuthComponent> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: provider.loading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: provider.phoneController,
                decoration: InputDecoration(
                  labelText: S.current.PhoneNumber,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Add verification code input
              TextField(
                controller: provider.codeController,
                decoration:  InputDecoration(
                  labelText: S.current.VerificationCode,
                  prefixIcon: const Icon(Icons.sms),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              provider.isCodeSent
                  ? SignInButton(
                      Buttons.anonymous,
                      text: S.current.SignIn,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onPressed: () => provider.onVerificationCodeSignIn(
                          context, widget.onSignIn),
                    )
                  : SignInButton(
                      Buttons.anonymous,
                      text: S.current.SendVerificationCode,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onPressed: () => provider.sendVerificationCode(context),
                    ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                  children: [
                    const TextSpan(text: 'By Signing in, you agree to our\n'),
                    TextSpan(
                      text: 'Terms of service',
                      style: const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = provider.openTermsOfService,
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = provider.openPrivacyPolicy,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
