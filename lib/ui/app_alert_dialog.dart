import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cocochat_app/ui/app_colors.dart';

class AppAlertDialogAction {
  String text;

  /// Font will be red and bold if set true.
  bool isDangerAction;
  VoidCallback action;

  AppAlertDialogAction(
      {required this.text, required this.action, this.isDangerAction = false});
}

Future<T?> showAppAlert<T>(
    {required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    AppAlertDialogAction? primaryAction,
    required List<AppAlertDialogAction> actions}) {
  List<Widget> actions0 = [];

  for (final action in actions) {
    if (Platform.isIOS) {
      actions0.add(
          CupertinoButton(onPressed: action.action, child: Text(action.text)));
    } else {
      actions0
          .add(TextButton(onPressed: action.action, child: Text(action.text)));
    }
  }

  if (primaryAction != null) {
    Widget pa;
    if (Platform.isIOS) {
      pa = CupertinoButton(
          onPressed: primaryAction.action,
          child: Text(primaryAction.text,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: primaryAction.isDangerAction
                      ? AppColors.errorRed
                      : null)));
    } else {
      pa = TextButton(
          onPressed: primaryAction.action,
          child: Text(primaryAction.text,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: primaryAction.isDangerAction
                      ? AppColors.errorRed
                      : null)));
    }
    actions0.add(pa);
  }

  final cont = content == null ? contentWidget : Text(content);

  return showDialog(
      context: context,
      builder: (context) {
        if (Platform.isIOS) {
          return CupertinoAlertDialog(
            title: Text(title),
            content: cont,
            actions: actions0,
          );
        } else {
          return AlertDialog(
            title: Text(title),
            content: cont,
            actions: actions0,
          );
        }
      });
}
