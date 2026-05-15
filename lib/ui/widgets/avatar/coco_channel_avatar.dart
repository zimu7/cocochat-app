import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cocochat_app/app.dart';
import 'package:cocochat_app/app_consts.dart';
import 'package:cocochat_app/dao/init_dao/group_info.dart';
import 'package:cocochat_app/services/coco_chat_service.dart';
import 'package:cocochat_app/services/file_handler/channel_avatar_handler.dart';
import 'package:cocochat_app/ui/app_icons_icons.dart';
import 'package:cocochat_app/ui/widgets/avatar/coco_avatar.dart';

class VoceChannelAvatar extends StatefulWidget {
  // General variables for all constructors
  final double size;
  final bool isCircle;

  final bool? _isDefaultPublicChannel;

  final GroupInfoM? groupInfoM;

  final Uint8List? avatarBytes;

  final String? name;

  final bool enableServerRetry;

  /// Builds a ChannelAvatar with GroupInfoM
  ///
  /// Widget will show letter avatar if avatarBytes are not available
  VoceChannelAvatar.channel(
      {super.key,
      required GroupInfoM this.groupInfoM,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableServerRetry = true})
      : name = groupInfoM.groupInfo.name,
        _isDefaultPublicChannel = groupInfoM.isPublic,
        avatarBytes = null;

  const VoceChannelAvatar.bytes(
      {super.key,
      required Uint8List this.avatarBytes,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableServerRetry = true})
      : groupInfoM = null,
        name = null,
        _isDefaultPublicChannel = null;

  const VoceChannelAvatar.name(
      {super.key,
      required String this.name,
      required this.size,
      this.isCircle = useCircleAvatar,
      this.enableServerRetry = true})
      : groupInfoM = null,
        _isDefaultPublicChannel = null,
        avatarBytes = null;

  const VoceChannelAvatar.defaultPublicChannel(
      {super.key, required this.size, this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        enableServerRetry = false,
        name = null,
        _isDefaultPublicChannel = true,
        avatarBytes = null;

  const VoceChannelAvatar.defaultPrivateChannel(
      {super.key, required this.size, this.isCircle = useCircleAvatar})
      : groupInfoM = null,
        enableServerRetry = false,
        name = null,
        _isDefaultPublicChannel = false,
        avatarBytes = null;

  @override
  State<VoceChannelAvatar> createState() => _VoceChannelAvatarState();
}

class _VoceChannelAvatarState extends State<VoceChannelAvatar> {
  @override
  void initState() {
    super.initState();
    App.app.chatService.subscribeGroups(_onChannelChanged);
  }

  @override
  void dispose() {
    App.app.chatService.unsubscribeGroups(_onChannelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupInfoM != null &&
        widget.groupInfoM!.groupInfo.avatarUpdatedAt != 0) {
      return FutureBuilder<File?>(
          future: ChannelAvatarHandler().readOrFetch(widget.groupInfoM!,
              enableServerRetry: widget.enableServerRetry),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return VoceAvatar.file(
                  file: snapshot.data!,
                  size: widget.size,
                  isCircle: widget.isCircle);
            } else {
              return _buildNonFileAvatar();
            }
          });
    } else {
      return _buildNonFileAvatar();
    }
  }

  Widget _buildNonFileAvatar() {
    if (widget.avatarBytes != null && widget.avatarBytes!.isNotEmpty) {
      return VoceAvatar.bytes(
          avatarBytes: widget.avatarBytes!,
          size: widget.size,
          isCircle: widget.isCircle);
    } else if (widget.name != null && widget.name!.isNotEmpty) {
      return VoceAvatar.name(
          name: widget.name!, size: widget.size, isCircle: widget.isCircle);
    } else if (widget._isDefaultPublicChannel ?? false) {
      return VoceAvatar.icon(
          icon: AppIcons.channel, size: widget.size, isCircle: widget.isCircle);
    } else {
      return VoceAvatar.icon(
          icon: AppIcons.private_channel,
          size: widget.size,
          isCircle: widget.isCircle);
    }
  }

  Future<void> _onChannelChanged(
      GroupInfoM groupInfoM, EventActions action, bool afterReady) async {
    if (groupInfoM.gid == widget.groupInfoM?.gid) {
      if (mounted && afterReady) {
        setState(() {});
      }
    }
  }
}
