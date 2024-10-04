import 'package:flutter/material.dart';

class AuthImageWidget extends StatelessWidget {
  final double sizeMultiplier;

  const AuthImageWidget({
    Key? key,
    this.sizeMultiplier = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3 * sizeMultiplier,
      child: Center(
        child: Image.asset(
          "assets/images/digital_brain3.png",
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}