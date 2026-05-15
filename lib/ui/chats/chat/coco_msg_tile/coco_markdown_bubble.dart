import 'package:flutter/material.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cocochat_app/dao/init_dao/chat_msg.dart';
import 'package:cocochat_app/shared_funcs.dart';
import 'package:cocochat_app/ui/app_colors.dart';

class VoceMdBubble extends StatelessWidget {
  final ChatMsgM chatMsgM;

  late final String? _mdText;

  late final bool _edited;

  VoceMdBubble({super.key, required this.chatMsgM}) {
    _mdText = chatMsgM.msgNormal?.content ?? chatMsgM.msgReply?.content;

    _edited = chatMsgM.reactionData?.hasEditedText ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(children: [
      MarkdownBody(
        data: _mdText ?? AppLocalizations.of(context)!.noContent,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
            a: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: AppColors.coolGrey700)),
        onTapLink: (text, url, title) {
          if (url != null) {
            SharedFuncs.appLaunchUrl(Uri.parse(url));
          }
        },
      ),
      if (_edited)
        Text(" (${AppLocalizations.of(context)!.edited})",
            style: TextStyle(
                fontSize: 14,
                color: AppColors.navLink,
                fontWeight: FontWeight.w400))
    ]);
  }
}
