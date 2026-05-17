## 2、联系人没有刷新的问题

在ContactDetailPage中，removeContact()、addContact()、blockContact()、unblockContact()这些方法更新了
  DB，但没有刷新_userInfoMNotifier，也没有调用fireUser()。因此，本地UI和其他组件（ContactList、CocoChatPage）没有收到通
  知。

  修复方法：每次联系人状态更改后，从DB获取更新后的UserInfoM，更新通知器，并触发用户事件。



## 1、sqlite3引用问题

根本原因：db.dart 原来直接使用 databaseFactoryFfi 作为全局 databaseFactory。sqflite_common_ffi 通过 FFI 加载
  libsqlite3.so，而 Android 系统不提供这个共享库，导致 sqlite3_initialize 解析失败，数据库初始化异常，后续访问 orgDb
  时触发 LateInitializationError。

  修改：
  1. 移除了 var databaseFactory = databaseFactoryFfi 的硬编码
  2. 在 initDb() 中按平台区分：

    - Android/iOS：使用 sqflite 包默认的 databaseFactory（由平台插件自动注册，使用原生 SQLite 实现，不需要
  libsqlite3.so）
    - 桌面端：调用 sqfliteFfiInit() 后设置 databaseFactory = databaseFactoryFfi
  3. 调整了 import 顺序，sqflite 优先于 sqflite_common_ffi，避免符号冲突

