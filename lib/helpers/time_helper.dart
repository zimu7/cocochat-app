import 'package:flutter/material.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';

extension TimeHelper on DateTime {
  String toTime24StringEn(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localtime = toLocal();

    final dateToCheck = DateTime(year, month, day);
    if (dateToCheck == today) {
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } else if (dateToCheck == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      final year = localtime.year.toString();
      final month = localtime.month.toString();
      final day = localtime.day.toString();

      return "$month/$day/$year";
    }
  }

  String toChatListTimeStr(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode != "zh") {
      return toTime24StringEn(context);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localtime = toLocal();
    final dateToCheck =
        DateTime(localtime.year, localtime.month, localtime.day);

    if (dateToCheck == today) {
      return "今天 ${localtime.toTime24Str()}";
    } else if (dateToCheck == yesterday) {
      return "昨天 ${localtime.toTime24Str()}";
    } else if (localtime.year == now.year) {
      return "${localtime.month}月${localtime.day}日";
    } else {
      return "${localtime.year}年${localtime.month}月${localtime.day}日";
    }
  }

  String toChatTime24StrEn(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localtime = toLocal();
    final dateToCheck =
        DateTime(localtime.year, localtime.month, localtime.day);
    final time = localtime.toTime24Str();

    if (Localizations.localeOf(context).languageCode == "zh") {
      if (dateToCheck == today) {
        return time;
      } else if (dateToCheck == yesterday) {
        return "昨天 $time";
      } else if (localtime.year == now.year) {
        return "${localtime.month}月${localtime.day}日 $time";
      } else {
        return "${localtime.year}年${localtime.month}月${localtime.day}日 $time";
      }
    }

    if (dateToCheck == today) {
      return "${AppLocalizations.of(context)!.today} $time";
    } else if (dateToCheck == yesterday) {
      return "${AppLocalizations.of(context)!.yesterday} $time";
    } else if (dateToCheck.year == localtime.year) {
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      return "$month/$day $time";
    } else {
      final year = localtime.year.toString();
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      return "$month/$day/$year $time";
    }
  }

  String toChatDateStrEn(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final localtime = toLocal();
    final dateToCheck = DateTime(year, month, day);
    if (dateToCheck == today) {
      return AppLocalizations.of(context)!.today;
    } else if (dateToCheck == yesterday) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (dateToCheck.year == now.year) {
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      return "$month/$day";
    } else {
      final year = localtime.year.toString();
      final month = localtime.month.toString();
      final day = localtime.day.toString();
      final hour = localtime.hour.toString();
      final minute = localtime.minute.toString().padLeft(2, '0');
      return "$month/$day/$year $hour:$minute";
    }
  }

  String toTime24Str() {
    final localtime = toLocal();

    final hour = localtime.hour.toString();
    final minute = localtime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  bool isToday() {
    final now = DateTime.now();
    return now.day == day && now.month == month && now.year == year;
  }

  bool isYesterday() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year;
  }
}

extension ChatTimeDisplay on int {
  /*
    microsecond: 1/100,000 second
    millisecond: 1/1,000 second
   */

  String toChatTime24StrEn(BuildContext context) {
    final messageTime = DateTime.fromMillisecondsSinceEpoch(this).toLocal();
    return messageTime.toChatTime24StrEn(context);
  }
}
