import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:cocochat_app/api/lib/group_api.dart';
import 'package:cocochat_app/api/models/group/group_create_request.dart';
import 'package:cocochat_app/api/models/group/group_create_response.dart';
import 'package:cocochat_app/api/models/group/group_info.dart';
import 'package:cocochat_app/app.dart';
import 'package:cocochat_app/app_consts.dart';
import 'package:cocochat_app/dao/init_dao/group_info.dart';
import 'package:cocochat_app/dao/init_dao/user_info.dart';
import 'package:cocochat_app/ui/app_colors.dart';
import 'package:cocochat_app/ui/app_text_styles.dart';
import 'package:cocochat_app/ui/contact/contact_list.dart';

class NewPrivateChannelSelectPage extends StatefulWidget {
  final List<UserInfoM> userList;
  final ValueNotifier<List<int>> selectedNotifier;

  final TextEditingController nameController;
  final TextEditingController desController;

  const NewPrivateChannelSelectPage(this.userList, this.selectedNotifier,
      this.nameController, this.desController, {super.key});

  @override
  State<NewPrivateChannelSelectPage> createState() =>
      _NewPrivateChannelSelectPageState();
}

class _NewPrivateChannelSelectPageState
    extends State<NewPrivateChannelSelectPage> {
  final List<int> preSelected = [App.app.userDb!.uid];

  late bool _enableDoneBtn;

  @override
  void initState() {
    super.initState();
    if (widget.selectedNotifier.value.length <= 1) {
      _enableDoneBtn = false;
    } else {
      _enableDoneBtn = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: barHeight,
        elevation: 0,
        backgroundColor: AppColors.coolGrey200,
        title: Text(AppLocalizations.of(context)!.newPrivateChannelSelectTitle,
            style: AppTextStyles.titleLarge,
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
        leading: CupertinoButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: Icon(Icons.arrow_back_ios_new_outlined,
                color: AppColors.grey97)),
        actions: [
          _enableDoneBtn
              ? CupertinoButton(
                  onPressed: () {
                    createChannel();
                  },
                  child: Text(AppLocalizations.of(context)!.done,
                      style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 17,
                          color: AppColors.primaryBlue)))
              : AbsorbPointer(
                  child: CupertinoButton(
                      onPressed: () {},
                      child: Text(AppLocalizations.of(context)!.done,
                          style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 17,
                              color: AppColors.grey400))),
                ),
        ],
      ),
      body: ContactList(
          initUserList: widget.userList,
          selectNotifier: widget.selectedNotifier,
          onTap: (userInfoM) {
            if (widget.selectedNotifier.value.contains(userInfoM.uid)) {
              widget.selectedNotifier.value =
                  List.from(widget.selectedNotifier.value)
                    ..remove(userInfoM.uid);
            } else {
              widget.selectedNotifier.value =
                  List.from(widget.selectedNotifier.value)..add(userInfoM.uid);
            }

            if (widget.selectedNotifier.value.length > 1) {
              setState(() {
                _enableDoneBtn = true;
              });
            } else {
              setState(() {
                _enableDoneBtn = false;
              });
            }
          },
          enablePreSelectAction: false,
          preSelectUidList: preSelected,
          enableSelect: true,
          enableUpdate: true),
    );
  }

  void createChannel() async {
    try {
      String name = widget.nameController.text.trim();
      if (name.isEmpty) {
        name = AppLocalizations.of(context)!.newPrivateChannel;
      }

      String description = widget.desController.text.trim();
      List<int>? members = widget.selectedNotifier.value;

      if (members.length < 2) {
        App.logger.severe("Member count not enough: ${members.length}");
        return;
      }

      final req = GroupCreateRequest(
          name: name,
          description: description,
          isPublic: false,
          members: members);

      await _createGroup(req);
    } catch (e) {
      App.logger.severe(e);
    }
    return;
  }

  Future<GroupCreateResponse?> _createGroupApi(GroupCreateRequest req) async {
    final groupApi = GroupApi();
    final res = await groupApi.create(req);
    if (res.statusCode == 200 && res.data != null) {
      return res.data!;
    }
    return null;
  }

  Future<void> _createGroup(GroupCreateRequest req) async {
    final groupCreateResponse = await _createGroupApi(req);
    if (groupCreateResponse == null || groupCreateResponse.gid == -1) {
      App.logger.severe("Group Creation Failed");
    } else {
      GroupInfo groupInfo = GroupInfo(
        groupCreateResponse.gid,
        App.app.userDb!.uid,
        req.name,
        req.description,
        req.members,
        false,
        0,
        [],
        true,
        true,
        false,
        true,
        null,
      );
      GroupInfoM groupInfoM = GroupInfoM.item(
        groupCreateResponse.gid,
        "",
        jsonEncode(groupInfo),
        "",
        0,
        1,
        groupCreateResponse.createdAt,
        1,
        1,
        0,
        1,
        "",
      );

      try {
        await GroupInfoDao()
            .addOrNotUpdate(groupInfoM)
            .then((value) {
          if (mounted) {
            Navigator.pop(context, value);
          }
        });
      } catch (e) {
        App.logger.severe(e);
        if (mounted) {
          Navigator.pop(context, groupInfoM);
        }
      }
    }
  }
}
