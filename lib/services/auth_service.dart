import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cocochat_app/api/lib/admin_system_api.dart';
import 'package:cocochat_app/api/lib/token_api.dart';
import 'package:cocochat_app/api/models/token/credential.dart';
import 'package:cocochat_app/api/models/token/login_response.dart';
import 'package:cocochat_app/api/models/token/token_login_request.dart';
import 'package:cocochat_app/app.dart';
import 'package:cocochat_app/dao/init_dao/user_info.dart';
import 'package:cocochat_app/dao/org_dao/chat_server.dart';
import 'package:cocochat_app/dao/org_dao/status.dart';
import 'package:cocochat_app/dao/org_dao/userdb.dart';
import 'package:cocochat_app/main.dart';
import 'package:cocochat_app/services/db.dart';
import 'package:cocochat_app/services/persistent_connection/sse.dart';
import 'package:cocochat_app/services/persistent_connection/web_socket.dart';
import 'package:cocochat_app/services/status_service.dart';
import 'package:cocochat_app/services/coco_chat_service.dart';
import 'package:cocochat_app/shared_funcs.dart';
import 'package:cocochat_app/ui/app_alert_dialog.dart';

class AuthService {
  static final AuthService _service = AuthService._internal();

  AuthService._internal();

  factory AuthService({required ChatServerM chatServerM}) {
    _service.chatServerM = chatServerM;
    _service.adminSystemApi = AdminSystemApi(serverUrl: chatServerM.fullUrl);

    App.app.chatServerM = chatServerM;

    return _service;
  }

  late ChatServerM chatServerM;
  late AdminSystemApi adminSystemApi;

  List<int> retryList = const [2, 2, 4, 8, 16, 32, 64];
  int retryIndex = 0;

  Timer? _fcmTimer;

  static const threshold = 60; // Refresh tokens if remaining time < 60.

  // ignore: unused_field
  final int _expiredIn = 0;

  void dispose() {}

  void disableFcmTimer() {
    _fcmTimer?.cancel();
  }

  Future<bool> tryReLogin() async {
    final userdb = App.app.userDb;
    if (userdb == null) return false;

    final dbName = App.app.userDb?.dbName;
    if (dbName == null || dbName.isEmpty) return false;

    final storage = FlutterSecureStorage();
    final pswd = await storage.read(key: dbName);

    if (pswd == null || pswd.isEmpty) return false;

    return login(userdb.userInfo.email!, pswd, true, true);
  }

  Future<TokenLoginRequest> _preparePswdLoginRequest(
      String email, String pswd) async {
    final deviceToken = "";
    final credential = Credential(email, pswd, "password");

    final req = TokenLoginRequest(
        device: await SharedFuncs.prepareDeviceInfo(),
        credential: credential,
        deviceToken: deviceToken);

    return req;
  }

  Future<bool> login(String email, String pswd, bool rememberPswd,
      [bool isReLogin = false]) async {
    String errorContent = "";
    try {
      final tokenApi = TokenApi(serverUrl: chatServerM.fullUrl);

      final req = await _preparePswdLoginRequest(email, pswd);
      final res = await tokenApi.tokenLoginPost(req);

      if (res.statusCode != 200) {
        switch (res.statusCode) {
          case 401:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent401;
            break;
          case 403:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent403;
            break;
          case 404:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent404;
            break;
          case 409:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent409;
            break;
          case 423:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent423;
            break;
          case 451:
            errorContent = AppLocalizations.of(navigatorKey.currentContext!)!
                .loginErrorContent451;
            break;
          default:
            App.logger.severe("Error: ${res.statusCode} ${res.statusMessage}");
            errorContent =
                "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther} ${res.statusCode} ${res.statusMessage}";
        }
      } else if (res.statusCode == 200 && res.data != null) {
        final data = res.data!;
        if (await initServices(data, rememberPswd,
            rememberPswd ? req.credential.password : null)) {
          await App.app.chatService.initPersistentConnection();
          return true;
        } else {
          errorContent =
              "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther}(initialization).";
        }
      } else {
        errorContent =
            "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther}  ${res.statusCode} ${res.statusMessage}";
      }
    } catch (e) {
      App.logger.severe(e);
      errorContent = e.toString();
    }

    await showAppAlert(
        context: navigatorKey.currentContext!,
        title: AppLocalizations.of(navigatorKey.currentContext!)!.loginError,
        content: errorContent,
        actions: [
          AppAlertDialogAction(
            text: AppLocalizations.of(navigatorKey.currentContext!)!.ok,
            action: () {
              Navigator.pop(navigatorKey.currentContext!);
            },
          )
        ]);

    return false;
  }

  Future<bool> initServices(LoginResponse res, bool rememberMe,
      [String? password]) async {
    try {
      final String serverId = res.serverId;
      final token = res.token;
      final refreshToken = res.refreshToken;
      final expiredIn = res.expiredIn;
      final userInfo = res.user;
      final userInfoJson = json.encode(userInfo.toJson());
      final dbName = "${serverId}_${userInfo.uid}";

      // Save password to secure storage.
      final storage = FlutterSecureStorage();
      if (rememberMe) {
        if (password != null && password.isNotEmpty) {
          await storage.write(key: dbName, value: password);
        }
      } else {
        await storage.delete(key: dbName);
      }

      final chatServerId = App.app.chatServerM.id;

      final old = await UserDbMDao.dao.first(
          where: '${UserDbM.F_chatServerId} = ? AND ${UserDbM.F_uid} = ?',
          whereArgs: [chatServerId, userInfo.uid]);

      late UserDbM newUserDb;
      if (old == null) {
        UserDbM m = UserDbM.item(
            userInfo.uid,
            userInfoJson,
            dbName,
            chatServerId,
            DateTime.now().millisecondsSinceEpoch,
            DateTime.now().millisecondsSinceEpoch,
            token,
            refreshToken,
            expiredIn,
            1,
            -1,
            "",
            0);
        newUserDb = await UserDbMDao.dao.addOrUpdate(m);
      } else {
        UserDbM m = UserDbM.item(
            userInfo.uid,
            userInfoJson,
            dbName,
            chatServerId,
            old.createdAt,
            DateTime.now().millisecondsSinceEpoch,
            token,
            refreshToken,
            expiredIn,
            1,
            old.usersVersion,
            "",
            old.maxMid);
        newUserDb = await UserDbMDao.dao.addOrUpdate(m);
      }

      App.app.userDb = newUserDb;
      StatusM statusM = StatusM.item(newUserDb.id);
      await StatusMDao.dao.replace(statusM);

      await initCurrentDb(dbName);

      final userInfoM = UserInfoM.fromUserInfo(userInfo, "");
      await UserInfoDao().addOrReplace(userInfoM);

      // Update chatServerM
      await ChatServerDao.dao.updateServerId(serverId).then((value) {
        if (value != null) {
          App.app.chatServerM = value;
        }
      });

      App.app.chatService = CocoChatService();
      App.app.statusService = StatusService();

      return true;
    } catch (e) {
      App.logger.severe(e);

      final context = navigatorKey.currentState?.context;
      if (context != null && context.mounted) {
        final error = e.toString();
        showAppAlert(
            context: context,
            title:
                AppLocalizations.of(navigatorKey.currentContext!)!.loginError,
            content:
                "${AppLocalizations.of(navigatorKey.currentContext!)!.loginErrorContentOther} (initialization).",
            actions: [
              AppAlertDialogAction(
                  text: AppLocalizations.of(navigatorKey.currentContext!)!
                      .loginErrorCopy,
                  action: () {
                    Clipboard.setData(ClipboardData(text: error));
                    Navigator.of(context).pop();
                  }),
              AppAlertDialogAction(
                  text: AppLocalizations.of(navigatorKey.currentContext!)!.ok,
                  action: () {
                    Navigator.of(context).pop();
                  })
            ]);
      }
    }

    return false;
  }

  Future<bool> logout({bool markLogout = true, bool isKicked = false}) async {
    try {
      VoceWebSocket().close();
      VoceSse().close();

      final curUserDb = App.app.userDb!;

      if (markLogout) {
        App.app.userDb = await UserDbMDao.dao.updateWhenLogout(curUserDb.id);
      }

      dispose();
      App.app.chatService.dispose();
      App.app.statusService?.dispose();

      if (!isKicked) {
        await closeUserDb();
      }

      final tokenApi = TokenApi();
      final res = await tokenApi.getLogout(curUserDb.token);

      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      App.logger.severe(e);
    }
    return false;
  }

  Future<bool> selfDelete() async {
    try {
      await logout();

      // Delete all data of this user.
      final path =
          "${(await getApplicationDocumentsDirectory()).path}/${App.app.userDb!.dbName}";
      await Directory(path).delete(recursive: true);

      // Delete user history data.
      await UserDbMDao.dao.remove(App.app.userDb!.id);
      final storage = FlutterSecureStorage();
      await storage.delete(key: App.app.userDb!.dbName);

      App.app.userDb = null;

      return true;
    } catch (e) {
      App.logger.severe(e);
      return false;
    }
  }
}
