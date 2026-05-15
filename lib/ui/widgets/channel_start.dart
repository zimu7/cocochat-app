import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cocochat_app/app.dart';
import 'package:cocochat_app/dao/init_dao/group_info.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:cocochat_app/ui/app_colors.dart';
import 'package:cocochat_app/ui/app_icons_icons.dart';
import 'package:cocochat_app/ui/app_text_styles.dart';
import 'package:cocochat_app/ui/chats/chat/chat_setting/channel/channel_info_page.dart';

class ChannelStart extends StatelessWidget {
  final ValueNotifier<GroupInfoM> groupInfoNotifier;
  final ValueNotifier<bool> isLoading;

  late final String _title;

  ChannelStart(this.groupInfoNotifier, this.isLoading, {super.key}) {
    _title = groupInfoNotifier.value.groupInfo.name;
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = App.app.userDb?.userInfo.isAdmin ?? false;
    bool isOwner =
        App.app.userDb?.uid == groupInfoNotifier.value.groupInfo.owner;

    return Container(
      // height: 100,
      width: double.maxFinite,
      padding: EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: AppLocalizations.of(context)!.channelStartWelcomeTo, style: AppTextStyles.titleLarge),
                  TextSpan(text: "#$_title", style: AppTextStyles.titleLarge)
                ])),
                SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.channelStartDes(_title),
                    style: AppTextStyles.snippet),
                SizedBox(height: 10),
                if (isOwner || isAdmin)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              ChannelInfoPage(groupInfoNotifier)
                          // ChannelSettingsPage(groupInfoNotifier: groupInfoNotifier),
                          ));
                    },
                    child: Row(
                      children: [
                        Icon(AppIcons.edit, size: 16),
                        SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.channelStartEditChannel,
                          style: TextStyle(fontSize: 16),
                        )
                      ],
                    ),
                  ),
                Divider(color: AppColors.grey400),
              ],
            ),
          ),
          Container(
            width: 24,
            padding: EdgeInsets.all(4),
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, value, child) {
                if (value) {
                  return CupertinoActivityIndicator();
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
