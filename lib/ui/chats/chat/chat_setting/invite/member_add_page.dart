import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:cocochat_app/api/lib/group_api.dart';
import 'package:cocochat_app/app.dart';
import 'package:cocochat_app/dao/init_dao/group_info.dart';
import 'package:cocochat_app/dao/init_dao/user_info.dart';
import 'package:cocochat_app/ui/app_colors.dart';
import 'package:cocochat_app/ui/app_text_styles.dart';
import 'package:cocochat_app/ui/contact/contact_list.dart';
import 'package:cocochat_app/ui/widgets/sheet_app_bar.dart';

class MemberAddPage extends StatefulWidget {
  final ValueNotifier<GroupInfoM> groupInfoMNotifier;

  const MemberAddPage(this.groupInfoMNotifier, {super.key});

  @override
  State<MemberAddPage> createState() => _MemberAddPageState();
}

class _MemberAddPageState extends State<MemberAddPage>
    with TickerProviderStateMixin {
  late final Future<List<UserInfoM>?> membersFuture;

  final ValueNotifier<List<int>> selectNotifier = ValueNotifier([]);

  bool enableInvitationLink = false;
  int tabCount = 1;

  @override
  void initState() {
    super.initState();
    membersFuture = prepareUserList();

    // int tabCount = widget.groupInfoM.groupInfo.isPublic ? 2 : 3;
    tabCount = widget.groupInfoMNotifier.value.groupInfo.isPublic
        ? 1
        : enableInvitationLink
            ? 2
            : 1;

    if (!widget.groupInfoMNotifier.value.isPublic) {
      selectNotifier.value =
          widget.groupInfoMNotifier.value.groupInfo.members ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Tab> tabs = [];
    List<Widget> tabViews = [];

    if (!widget.groupInfoMNotifier.value.isPublic) {
      tabs.insert(
          0, Tab(text: AppLocalizations.of(context)!.memberAddPageAddMembers));
      tabViews.insert(0, _buildMembersTab());
    }

    return Column(
      children: [
        SheetAppBar(
          title: Text(
            AppLocalizations.of(context)!.memberAddPageTitle,
            style: AppTextStyles.titleLarge,
          ),
          leading: CupertinoButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.close, color: AppColors.grey97)),
          actions: [_buildAddBtn()],
        ),
        Flexible(child: _buildMembersTab())
      ],
    );
  }

  Widget _buildMembersTab() {
    return FutureBuilder<List<UserInfoM>?>(
        future: membersFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ContactList(
                initUserList: snapshot.data!,
                ownerUid: widget.groupInfoMNotifier.value.groupInfo.owner,
                onTap: (user) {
                  if (selectNotifier.value.contains(user.uid)) {
                    selectNotifier.value =
                        List<int>.from(selectNotifier.value..remove(user.uid));
                  } else {
                    selectNotifier.value =
                        List<int>.from(selectNotifier.value..add(user.uid));
                  }
                },
                preSelectUidList:
                    widget.groupInfoMNotifier.value.groupInfo.members,
                selectNotifier: selectNotifier,
                enableSelect: true,
                enablePreSelectAction: false);
          }
          return SizedBox.shrink();
        });
  }

  Future<List<UserInfoM>?> prepareUserList() async {
    return UserInfoDao().getUserList();
  }

  Widget _buildAddBtn() {
    if (widget.groupInfoMNotifier.value.isPublic) {
      return SizedBox.shrink();
    }
    return ValueListenableBuilder<List<int>>(
        valueListenable: selectNotifier,
        builder: (context, uidList, _) {
          final addCount = uidList.length -
              widget.groupInfoMNotifier.value.groupInfo.members!.length;

          final countText = addCount > 0 ? "($addCount)" : "";

          final btnText =
              AppLocalizations.of(context)!.memberAddPageAdd + countText;
          return CupertinoButton(
              onPressed: () async {
                setState(() {});

                try {
                  final adds = selectNotifier.value.where((element) => !widget
                      .groupInfoMNotifier.value.groupInfo.members!
                      .contains(element));
                  final groupApi = GroupApi();
                  final hasSent = await groupApi.addMembers(
                      widget.groupInfoMNotifier.value.gid, adds.toList());
                  if (hasSent.statusCode == 200) {
                    setState(() {
                      Navigator.of(context).pop();
                    });
                  }
                } catch (e) {
                  App.logger.severe(e);

                  setState(() {});
                }
              },
              child: Text(
                btnText,
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: AppColors.primaryBlue),
              ));
        });
  }
}
