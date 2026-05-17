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

