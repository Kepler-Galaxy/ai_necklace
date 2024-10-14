import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

class EmptyMemoriesWidget extends StatefulWidget {
  const EmptyMemoriesWidget({super.key});

  @override
  State<EmptyMemoriesWidget> createState() => _EmptyMemoriesWidgetState();
}

class _EmptyMemoriesWidgetState extends State<EmptyMemoriesWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 240.0),
      child: Text(
        S.current.NoMemoriesGeneratedYet,
        style: const TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}
