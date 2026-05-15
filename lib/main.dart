import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cocochat_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:app_links/app_links.dart';
import 'package:cocochat_app/app.dart';
import 'package:cocochat_app/dao/org_dao/chat_server.dart';
import 'package:cocochat_app/dao/org_dao/status.dart';
import 'package:cocochat_app/dao/org_dao/userdb.dart';
import 'package:cocochat_app/services/auth_service.dart';
import 'package:cocochat_app/services/db.dart';
import 'package:cocochat_app/services/persistent_connection/web_socket.dart';
import 'package:cocochat_app/services/status_service.dart';
import 'package:cocochat_app/services/coco_chat_service.dart';
import 'package:cocochat_app/shared_funcs.dart';
import 'package:cocochat_app/ui/app_colors.dart';
import 'package:cocochat_app/ui/chats/chats/chats_main_page.dart';
import 'package:cocochat_app/ui/chats/chats/chats_page.dart';
import 'package:cocochat_app/ui/contact/contacts_page.dart';
import 'package:cocochat_app/ui/settings/settings_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  App.logger.setLevel(Level.CONFIG, includeCallerInfo: true);

  await initDb();

  Widget defaultHome = ChatsMainPage();

  // Handling login status
  final status = await StatusMDao.dao.getStatus();
  if (status == null) {
    defaultHome = await SharedFuncs.getDefaultHomePage();
  } else {
    final userDb = await UserDbMDao.dao.getUserDbById(status.userDbId);
    if (userDb == null) {
      defaultHome = await SharedFuncs.getDefaultHomePage();
    } else {
      App.app.userDb = userDb;
      await initCurrentDb(App.app.userDb!.dbName);

      if (userDb.loggedIn != 1) {
        VoceWebSocket().close();
        defaultHome = await SharedFuncs.getDefaultHomePage();
      } else {
        final chatServerM =
            await ChatServerDao.dao.getServerById(userDb.chatServerId);
        if (chatServerM == null) {
          defaultHome = await SharedFuncs.getDefaultHomePage();
        } else {
          App.app.chatServerM = chatServerM;

          App.app.statusService = StatusService();
          App.app.authService = AuthService(chatServerM: App.app.chatServerM);
          App.app.chatService = CocoChatService();
        }
      }
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) {
    runApp(CocoChatApp(defaultHome: defaultHome));
  });
}

// ignore: must_be_immutable
class CocoChatApp extends StatefulWidget {
  CocoChatApp({required this.defaultHome, super.key});

  late Widget defaultHome;

  // ignore: library_private_types_in_public_api
  static _CocoChatAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_CocoChatAppState>();

  @override
  State<CocoChatApp> createState() => _CocoChatAppState();
}

class _CocoChatAppState extends State<CocoChatApp> with WidgetsBindingObserver {
  late Widget _defaultHome;

  /// Whether the app should fetch new tokens from server.
  ///
  /// When app lifecycle goes through [paused] and [detached], it is set to true.
  /// When app lifecycle goes through [resumed], it is set back to false.
  bool shouldRefresh = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Locale? _locale;

  /// When network changes, such as from wi-fi to data, a relay is set to avoid
  /// [_connect()] function to be called repeatly.
  bool _isConnecting = false;

  bool _firstTimeRefreshSinceAppOpens = true;

  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _defaultHome = widget.defaultHome;

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    _initLocale();

    _handleIncomingUniLink();
    _handleInitUniLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        App.logger.info('App lifecycle: app resumed');

        onResume();

        shouldRefresh = false;

        break;
      case AppLifecycleState.paused:
        App.logger.info('App lifecycle: app paused');

        shouldRefresh = true;

        break;
      case AppLifecycleState.inactive:
        App.logger.info('App lifecycle: app inactive');
        break;
      case AppLifecycleState.detached:
      default:
        App.logger.info('App lifecycle: app detached');

        shouldRefresh = true;

        break;
    }
  }

  void _initLocale() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final savedLocale = sharedPreferences.getString('locale');
    if (savedLocale != null) {
      setState(() {
        _locale = Locale(savedLocale);
      });
    } else {
      setState(() {
        _locale = View.of(context).platformDispatcher.locale;
      });
    }
  }

  void setUILocale(Locale newLocale) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _locale = newLocale;
    });
    await sharedPreferences.setString('locale', newLocale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'CocoChat',
        routes: {
          // Auth
          // ServerPage.route: (context) => ServerPage(),
          // LoginPage.route: (context) => LoginPage(),
          // Chats
          ChatsMainPage.route: (context) => ChatsMainPage(),
          ChatsPage.route: (context) => ChatsPage(),
          // Contacts
          ContactsPage.route: (context) => ContactsPage(),
          // ContactDetailPage.route: (context) => ContactDetailPage(),
          // Settings
          SettingPage.route: (context) => SettingPage(),
        },
        theme: ThemeData(
            // canvasColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: AppColors.grey200,
            fontFamily: 'Inter',
            primarySwatch: Colors.blue,
            dividerTheme: DividerThemeData(thickness: 0.5, space: 1),
            textTheme: TextTheme(
                // headline6:
                // Chats tile title, contacts
                // titleSmall: ,
                // titleMedium:
                //     TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                // All AppBar titles
                titleLarge:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        // theme: ThemeData.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: _locale,
        supportedLocales: const [
          Locale('en', ''), // English, no country code
          Locale('zh', ''),
        ],
        home: _defaultHome,
      ),
    );
  }

  void switchServerOnNotification(String serverId, int? uid, int? gid) async {}

  void _handleIncomingUniLink() async {
    _appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      _parseLink(uri);
    });
  }

  void _handleInitUniLink() async {
    final initialUri = await _appLinks.getLatestLink();
    if (initialUri == null) return;
    _parseLink(initialUri);
  }

  void _parseLink(Uri uri) async {
    App.logger.info("UniLink/DeepLink: $uri");
    await SharedFuncs.parseUniLink(uri);
  }

  void onResume() async {
    try {
      if (App.app.authService == null) {
        return;
      }

      // if pre is inactive, do nothing.
      if (!shouldRefresh) {
        return;
      }

      await _connect();
    } catch (e) {
      App.logger.severe(e);
      if (App.app.authService == null) {
        return;
      }

      App.app.authService!.logout().then((value) async {
        final defaultHomePage = await SharedFuncs.getDefaultHomePage();
        if (value) {
          navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => defaultHomePage,
              ),
              (route) => false);
        } else {
          navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => defaultHomePage,
              ),
              (route) => false);
        }
      });
    }
  }

  void onPaused() {}

  void onInactive() {}

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    App.logger.info("Connectivity: $results");
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.none)) {
      await _connect();
    }
  }

  Future<void> _connect() async {
    if (_isConnecting) return;

    _isConnecting = true;

    final status = await StatusMDao.dao.getStatus();
    if (status != null) {
      final userDb = await UserDbMDao.dao.getUserDbById(status.userDbId);
      if (userDb != null) {
        if (App.app.authService != null) {
          if (await SharedFuncs.renewAuthToken(
              forceRefresh: _firstTimeRefreshSinceAppOpens)) {
            _firstTimeRefreshSinceAppOpens = false;
            await App.app.chatService.initPersistentConnection();
          } else {
            VoceWebSocket().close();
          }
        }
      }
    }

    _isConnecting = false;
    return;
  }
}

class InvitationLinkData {
  String serverUrl;
  String magicToken;

  InvitationLinkData({required this.serverUrl, required this.magicToken});
}

class UniLinkData {
  String link;
  UniLinkType type;

  UniLinkData({required this.link, required this.type});
}

enum UniLinkType { login, register }
