## 5、修复联系人按钮添加的问题

@lib/ui/contact/contact_detail_page.dart  从这个contact_detail_page.dart进入聊天详情页面，不管是否添加了联系人，都会
  出现添加联系人的按钮，请检查一下是哪里的问题。

找到问题了。在 UserInfoDao.addOrUpdate 方法中，当 old == m 时（用户信息没有实际变化），方法直接返回 old，但 old 是通过
   first() / fromMap 获取的，contactStatusStr 未从数据库读取，默认为 "none"。而联系状态修正代码在 return old
  之后，不会被执行。

  这导致当服务端推送用户更新事件（如上线/下线状态变化）而用户信息本身没变时，fireUser 发出的 UserInfoM 的
  contactStatusStr 为 "none"，ContactDetailPage._onUser 收到后覆盖了 _userInfoMNotifier，使 CocoChatPage
  看到的联系人状态变为 none，从而始终显示"添加联系人"按钮。

修复方式：不再提前 return，而是将 m = old 后继续执行后面的联系状态修正逻辑。这样无论记录是否更新，都会从 contacts
  表中正确读取 contactStatusStr。



## 4、隐藏掉一些尚未实现的或不需要的功能

- 首页+按钮出来的，邀请新用户、扫描二维码两个按钮给隐藏掉，相关的代码可以先不用处理。
- 将侧边栏中输入邀请链接的按钮给隐藏掉。
- 隐藏掉首页的“输入邀请链接”链接文字。



## 3、修正文件下载的问题

修复文件下载保存的问题，使用 file_saver 库。



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

