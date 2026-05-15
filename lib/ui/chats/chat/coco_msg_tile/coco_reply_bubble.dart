import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:cocochat_app/dao/init_dao/chat_msg.dart';
import 'package:cocochat_app/dao/init_dao/user_info.dart';
import 'package:cocochat_app/models/ui_models/audio_info.dart';
import 'package:cocochat_app/models/ui_models/msg_tile_data.dart';
import 'package:cocochat_app/services/file_handler.dart';
import 'package:cocochat_app/ui/app_colors.dart';
import 'package:cocochat_app/ui/chats/chat/message_tile/image_bubble/tile_image_bubble.dart';
import 'package:cocochat_app/ui/chats/chat/coco_msg_tile/audio/coco_audio_bubble.dart';
import 'package:cocochat_app/ui/chats/chat/coco_msg_tile/coco_archive_bubble.dart';
import 'package:cocochat_app/ui/chats/chat/coco_msg_tile/coco_file_bubble.dart';
import 'package:cocochat_app/ui/chats/chat/coco_msg_tile/coco_text_bubble.dart';
import 'package:cocochat_app/ui/widgets/avatar/coco_avatar_size.dart';
import 'package:cocochat_app/ui/widgets/avatar/coco_user_avatar.dart';

// ignore: must_be_immutable
class VoceReplyBubble extends StatefulWidget {
  final MsgTileData? tileData;

  final ValueNotifier<ChatMsgM?> repliedMsgMNotifier;
  final UserInfoM? repliedUser;

  final File? repliedImageFile;
  final AudioInfo? repliedAudioInfo;

  VoceReplyBubble.tileData({super.key, required MsgTileData this.tileData})
      : repliedMsgMNotifier = tileData.repliedMsgMNotifier,
        repliedUser = tileData.repliedUserInfoM,
        repliedImageFile = tileData.repliedImageFile,
        repliedAudioInfo = tileData.repliedAudioInfo;

  const VoceReplyBubble.data({
    super.key,
    required ValueNotifier<ChatMsgM> this.repliedMsgMNotifier,
    required UserInfoM this.repliedUser,
    this.repliedImageFile,
    this.repliedAudioInfo,
  })  : tileData = null;

  @override
  State<VoceReplyBubble> createState() => _VoceReplyBubbleState();
}

class _VoceReplyBubbleState extends State<VoceReplyBubble> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.cyan100, borderRadius: BorderRadius.circular(4)),
      child: _buildBubble(),
    );
  }

  Widget _buildBubble() {
    return ValueListenableBuilder<ChatMsgM?>(
        valueListenable: widget.repliedMsgMNotifier,
        builder: (context, repliedMsgM, child) {
          if (repliedMsgM == null) {
            return Text(AppLocalizations.of(context)!.repliedMessageDeleted,
                style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF344054)));
          } else {
            final userInfoM = widget.repliedUser ?? UserInfoM.deleted();
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    VoceUserAvatar.user(
                        userInfoM: userInfoM,
                        size: VoceAvatarSize.s18,
                        enableOnlineStatus: false),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(userInfoM.userInfo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Color(0xFF344054))),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: VoceAvatarSize.s18 + 8),
                  child: _buildContentBubble(repliedMsgM),
                )
              ],
            );
          }
        });
  }

  Widget _buildContentBubble(ChatMsgM repliedMsgM) {
    final key = ValueKey(repliedMsgM.localMid);

    if (repliedMsgM.isTextMsg) {
      return VoceTextBubble(key: key, chatMsgM: repliedMsgM, maxLines: 2);
    } else if (repliedMsgM.isMarkdownMsg) {
      // Use text bubble to display markdown reply.
      return VoceTextBubble(key: key, chatMsgM: repliedMsgM, maxLines: 2);
    } else if (repliedMsgM.isFileMsg) {
      if (repliedMsgM.isImageMsg) {
        return VoceTileImageBubble.reply(key: key, tileData: widget.tileData!);
      } else {
        final msgNormal = repliedMsgM.msgNormal!;
        final path = msgNormal.content;
        final name = msgNormal.properties?["name"] ?? "";
        final size = msgNormal.properties?["size"] ?? 0;
        return VoceFileBubble.reply(
            key: key,
            filePath: path,
            name: name,
            size: size,
            getLocalFile: () => FileHandler.singleton.getLocalFile(repliedMsgM),
            getFile: (onProgress) =>
                FileHandler.singleton.getFile(repliedMsgM, onProgress));
      }
    } else if (repliedMsgM.isAudioMsg) {
      return VoceAudioBubble.data(
          key: key, audioInfo: widget.tileData!.repliedAudioInfo, height: 24);
    } else if (repliedMsgM.isArchiveMsg) {
      return VoceArchiveBubble.tileData(key: key, tileData: widget.tileData!);
    }
    return Text(AppLocalizations.of(context)!.unsupportedMessageType);
  }
}
