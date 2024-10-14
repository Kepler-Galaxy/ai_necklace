import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foxxy_package/generated/l10n.dart';

//TODO: switch to required named parameters
getDialog(
  BuildContext context,
  Function onCancel,
  Function onConfirm,
  String title,
  String content, {
  bool singleButton = false,
  String okButtonText = 'Ok',
}) {
  var actions = singleButton
      ? [
          TextButton(
            onPressed: () => onCancel(),
            child:
                Text(S.current.Ok, style: const TextStyle(color: Colors.white)),
          )
        ]
      : [
          TextButton(
            onPressed: () => onCancel(),
            child:
                Text(S.current.Cancel, style: TextStyle(color: Colors.white)),
          ),
          TextButton(
              onPressed: () => onConfirm(),
              child: Text(S.current.Ok,
                  style: const TextStyle(color: Colors.white))),
        ];
  if (Platform.isIOS) {
    return CupertinoAlertDialog(
        title: Text(title), content: Text(content), actions: actions);
  }
  return AlertDialog(
      title: Text(title), content: Text(content), actions: actions);
}
