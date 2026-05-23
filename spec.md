## 9、优化日期展示

1、消息列表页面，在中文环境下，如果是今天的，就写类似于： 今天 14:32，注意时间用24小时制。如果是昨天的，就写类似于： 昨天 14：32，再往前如果是本年的，就写类似于： 5月2日，本年的不要年份。如果是去年或更早的，就写：2025年4月2日，不要时分秒。

2、消息详情页面中，如果是今天的，就写类似于：14:32 这样，24小时制，不要日期和秒。 如果是昨天的，就写类似于：昨天 14:32， 再往前如果是本年的，就写类似于： 5月2日 14:32，本年的不要年份。如果是去年或更早的，就写：2025年4月2日 14:32，不要秒。

## 8、优化textbubble

优化textbubble。

## 7、修复频道修改页面报错的问题

 修复完成。updateGroup 方法缺少两样东西：
  1. content-type: application/json header — Dio 无法从自定义对象推断 content-type，导致 415
  2. json.encode(req.toJson()) — 需要手动序列化为 JSON 字符串

  这与同文件中 create、addMembers 等方法的做法一致。



## 6、修复创建频道（channel）报错的问题

报错信息：

I/flutter (13875): 👻 INFO 2026-05-20 15:18:23.009623 [package:cocochat_app/services/persistent_connection/sse.dart 55:20 in VoceSse.connect.<fn>] {"group":{"avatar_updated_at":1779290308012,"description":"test","gid":18,"is_public":false,"members":[1,2,4],"name":"test","owner":1,"pinned_messages":[]},"type":"joined_group"}
I/flutter (13875): ‼️ SEVERE 2026-05-20 15:18:23.115207 [package:cocochat_app/ui/chats/chats/new/new_private_channel_select_page.dart 153:18 in _NewPrivateChannelSelectPageState.createChannel] type '_Map<String, dynamic>' is not a subtype of type 'int' in type cast



问题原因：

 - group_api.dart：createBfe033 返回类型从 Response<int> 改为 Response<GroupCreateResponse>，用 fromJson
     解析响应而非强转 int
  - new_private_channel_select_page.dart：createGroupBfe033 返回 GroupCreateResponse?，_createGroupBfe033 使用
      groupCreateResponse.gid
  - new_channel_page.dart：同上

  根因是服务端 API 返回的是 JSON 对象 {"gid": ..., "created_at": ...}，但旧版代码还在尝试把整个 Map 强转为 int。



修改：

- group_api.dart：删除 createBfe033 和 createAft033，合并为一个 create 方法
- new_private_channel_select_page.dart：删除版本判断逻辑、isVersionNumberGreaterThan、两套创建方法，统一为
  _createGroup；移除 admin_system_api import
- new_channel_page.dart：同上，删除版本判断和两套方法，统一为 _createGroup；移除 admin_system_api import



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

