import 'package:flutter/material.dart';
import 'package:cocochat_app/dao/org_dao/chat_server.dart';
import 'package:cocochat_app/dao/org_dao/status.dart';
import 'package:cocochat_app/dao/org_dao/userdb.dart';
import 'package:cocochat_app/event_bus_objects/user_change_event.dart';
import 'package:cocochat_app/globals.dart';
import 'package:cocochat_app/main.dart';
import 'package:cocochat_app/models/custom_configs/v0.1/custom_configs_0.1.dart';
import 'package:cocochat_app/services/auth_service.dart';
import 'package:cocochat_app/services/coco_chat_service.dart';
import 'package:cocochat_app/services/db.dart';
import 'package:cocochat_app/services/status_service.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:cocochat_app/shared_funcs.dart';

import 'UI/chats/chats/chats_main_page.dart';

/// A place for app infos and services.
class App {
  static final App app = App._internal();

  static final logger = SimpleLogger();

  CustomConfigs0001? customConfig;

  // initialized in login page.
  StatusService? statusService;
  AuthService? authService;

  // initialized after a successful login action.
  late CocoChatService chatService;

  // initialized in login page
  UserDbM? userDb;

  // will be updated in ChatService. No need to handle manually.
  Map<int, ValueNotifier<bool>> onlineStatusMap = {};

  ChatServerM chatServerM = ChatServerM();

  factory App() {
    return app;
  }

  Future<void> changeUser(UserDbM userDbM) async {
    // Wait until all current tasks has been done to avoid data interference.
    await Future.doWhile(
      () async {
        await Future.delayed(Duration(milliseconds: 500));
        return App.app.chatService.eventQueue.isProcessing;
      },
    );

    // Switch database
    await closeUserDb();
    await initCurrentDb(userDbM.dbName);

    final userDbId = userDbM.id;

    // Update StatusM (only has one status at a time)
    final statusM = StatusM.item(userDbId);
    await StatusMDao.dao.removeAll();
    await StatusMDao.dao.addOrReplace(statusM);

    chatServerM =
        (await ChatServerDao.dao.getServerById(userDbM.chatServerId))!;

    // Update Services
    authService?.dispose();
    chatService.dispose();
    statusService?.dispose();

    userDb = userDbM;
    statusService = StatusService();
    authService = AuthService(chatServerM: chatServerM);
    chatService = CocoChatService();

    final navigator = navigatorKey.currentState;

    if (navigator != null) {
      navigator.popUntil((route) => route.isFirst);
      navigator.pushReplacement(MaterialPageRoute(
        builder: (context) => ChatsMainPage(),
      ));
    }

    eventBus.fire(UserChangeEvent(userDbM));

    // connect
    if (authService != null) {
      if (await SharedFuncs.renewAuthToken()) {
        await chatService.initPersistentConnection();
      }
    }
  }

  Future<void> changeUserAfterLogOut() async {
    final loggedInUserDbList =
        (await UserDbMDao.dao.getList())?.where((e) => e.loggedIn == 1) ?? [];

    if (loggedInUserDbList.isEmpty) {
      final defaultHomePage = await SharedFuncs.getDefaultHomePage();
      navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => defaultHomePage,
          ),
          (route) => false);
      return;
    } else {
      final next = loggedInUserDbList.first;
      await changeUser(next);
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(ChatsMainPage.route, (route) => false);
    }
  }

  App._internal();
}

class AuthData {
  final String token;
  final String refreshToken;
  final int expiredIn;
  // final UserInfo user;

  AuthData(
      {required this.token,
      required this.refreshToken,
      required this.expiredIn});
}
