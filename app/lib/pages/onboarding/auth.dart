import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:friend_private/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:friend_private/generated/l10n.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:flutter/services.dart';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,      // 只允许输入数字
                  LengthLimitingTextInputFormatter(11),        // 限制为 11 位
                ],
                decoration: InputDecoration(
                  labelText: S.current.PhoneNumber,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.phone, size: 20, color: Theme.of(context).iconTheme.color),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Add verification code input
              TextField(
                controller: provider.codeController,
                decoration:  InputDecoration(
                  labelText: S.current.VerificationCode,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.sms, size: 20, color: Theme.of(context).iconTheme.color),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: const GradientBoxBorder(
                    gradient: LinearGradient(colors: [
                      Color.fromARGB(127, 208, 208, 208),
                      Color.fromARGB(127, 188, 99, 121),
                      Color.fromARGB(127, 86, 101, 182),
                      Color.fromARGB(127, 126, 190, 236)
                    ]),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: provider.isCodeSent
                      ? () => provider.onVerificationCodeSignIn(context, widget.onSignIn)
                      : () => provider.sendVerificationCode(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      provider.isCodeSent ? S.current.SignIn : S.current.SendVerificationCode,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  children: [
                    const TextSpan(text: 'By Signing in, you agree to our\n'),
                    TextSpan(
                      text: 'Terms of Service and Privacy Policy',
                      style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
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
