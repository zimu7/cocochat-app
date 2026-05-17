# CocoChat App



CocoChat android and ios application.

# how to build

## 1、install flutter

## 2、install dependencies

```
flutter pub get
```

## 3、build apk

need a long time.

### 3.1 install android sdk

### 3.2 install dependencies

```bash
flutter pub get
```

### 3.3 create sign file

use the follow command to create sign file, notice to replace storepass and keypass.

```bash
cd ocochat-app/android
keytool -genkey -v -keystore app/cocochat-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cocochat -storepass xxxx -keypass yyyy -dname "CN=zimu, OU=zimu, O=zimu, L=Beijing, ST=Beijing, C=CN"
```

signed file will be stored to : app/cocochat-release.jks

### 3.4 create key.properties

android\key.properties

```ini
storePassword=xxxx
keyPassword=yyyy
keyAlias=cocochat
storeFile=cocochat-release.jks
```

### 3.5 build

build release version

```bash
flutter build apk --release
```

## 4、build ios

TODO



# project structure

```
cocochat-app/
├── android/                  # Android native project files
├── assets/                   # Static assets (SQL schemas, fonts, images, changelog)
├── ios/                      # iOS native project files
├── lib/                      # Main Dart/Flutter source code
│   ├── api/                  # API layer — HTTP clients and data models
│   │   ├── lib/              # API client implementations
│   │   │   ├── admin_*.dart  # Admin APIs (login, SMTP, system, user)
│   │   │   ├── group_api.dart       # Group/channel API
│   │   │   ├── message_api.dart     # Message API
│   │   │   ├── resource_api.dart    # File/resource upload API
│   │   │   ├── saved_api.dart       # Saved/bookmarked messages API
│   │   │   ├── token_api.dart       # Auth token API
│   │   │   ├── user_api.dart        # User API
│   │   │   ├── dio_util.dart        # Dio HTTP client setup
│   │   │   └── dio_retry/           # Retry interceptor for Dio
│   │   └── models/           # JSON-serializable API request/response models
│   │       ├── admin/        # Admin-related models (login, SMTP, system)
│   │       ├── group/        # Group create/update/info models
│   │       ├── msg/          # Chat message, reactions, reply, archive models
│   │       ├── resource/     # File upload and OpenGraph models
│   │       ├── saved/        # Saved message models
│   │       ├── server/       # Server info models
│   │       ├── token/        # Credential, login, renew, Agora token models
│   │       └── user/         # Contact info, registration, user info models
│   ├── dao/                  # Data Access Object — local database layer
│   │   ├── dao.dart          # Base DAO class
│   │   ├── init_dao/         # Per-user database DAOs (chat messages, contacts, etc.)
│   │   │   ├── chat_msg.dart          # Chat message persistence
│   │   │   ├── contacts.dart         # Contact persistence
│   │   │   ├── group_info.dart       # Group/channel info persistence
│   │   │   ├── dm_info.dart          # Direct message info persistence
│   │   │   ├── archive.dart          # Archived messages persistence
│   │   │   ├── reaction.dart         # Message reactions persistence
│   │   │   ├── saved.dart            # Saved messages persistence
│   │   │   ├── user_info.dart        # User info persistence
│   │   │   ├── user_settings.dart    # User settings persistence
│   │   │   ├── open_graphic_thumbnail.dart  # Link preview thumbnails
│   │   │   └── properties_models/    # Property models for groups/users/settings
│   │   └── org_dao/          # Organization-level database DAOs
│   │       ├── chat_server.dart      # Chat server info persistence
│   │       ├── userdb.dart           # User database persistence
│   │       ├── status.dart           # Status persistence
│   │       └── properties_models/    # Property models for chat server/userdb
│   ├── event_bus_objects/    # Event bus event definitions
│   ├── helpers/              # Utility helpers (shared preferences, time formatting)
│   ├── l10n/                 # Internationalization (English & Chinese localizations)
│   ├── mixins/               # Dart mixins (e.g., orientation handling)
│   ├── models/               # Domain models
│   │   ├── custom_configs/   # Versioned custom configuration models
│   │   ├── share_extension/  # Share extension data models
│   │   └── ui_models/        # UI-specific models (audio info, chat tile data, etc.)
│   ├── packages/             # Bundled local packages
│   │   ├── azlistview/       # Alphabetically-indexed list view
│   │   └── voce_widgets/     # Custom widget library (buttons, text fields)
│   ├── services/             # Core business services
│   │   ├── auth_service.dart           # Authentication service
│   │   ├── coco_chat_service.dart      # Main chat service orchestrator
│   │   ├── coco_send_service.dart      # Message sending service
│   │   ├── coco_audio_service.dart     # Audio playback/recording service
│   │   ├── db.dart                      # Database initialization and management
│   │   ├── status_service.dart          # Online/status service
│   │   ├── task_queue.dart              # Generic task queue
│   │   ├── file_uploader.dart           # File upload service
│   │   ├── file_handler/               # File handling strategies per type
│   │   │   ├── voce_file_handler.dart      # Base file handler
│   │   │   ├── audio_file_handler.dart     # Audio file handler
│   │   │   ├── archive_handler.dart        # Archive file handler
│   │   │   ├── user_avatar_handler.dart    # User avatar handler
│   │   │   ├── user_bg_handler.dart        # User background handler
│   │   │   ├── channel_avatar_handler.dart # Channel avatar handler
│   │   │   ├── channel_bg_handler.dart     # Channel background handler
│   │   │   └── video_thumb_handler.dart    # Video thumbnail handler
│   │   ├── persistent_connection/      # Persistent connection (SSE & WebSocket)
│   │   ├── send_task_queue/            # Message send task queue
│   │   └── sse/                        # Server-Sent Events handling
│   ├── ui/                   # UI layer — pages and widgets
│   │   ├── auth/             # Authentication pages (login, register, server setup)
│   │   ├── chats/            # Chat feature pages
│   │   │   ├── chat/         # Individual chat page and message tiles
│   │   │   │   ├── chat_setting/     # Chat settings (channel, DM, invite, pinned)
│   │   │   │   ├── coco_msg_tile/    # Message bubble widgets (text, audio, file, etc.)
│   │   │   │   ├── input_field/      # Chat input (text field, mentions, voice)
│   │   │   │   ├── message_tile/     # Message display tiles (image, video, markdown)
│   │   │   │   └── msg_actions/      # Message action sheet (reply, forward, etc.)
│   │   │   └── chats/        # Chat list page (drawer, new DM/channel)
│   │   ├── contact/          # Contact list and detail pages
│   │   ├── settings/         # Settings pages (user info, language, changelog, about)
│   │   └── widgets/          # Shared reusable widgets
│   │       ├── avatar/       # Avatar widgets (user, channel, size definitions)
│   │       ├── banner_tile/  # Banner tile components
│   │       └── search/       # Search field and results widgets
│   ├── app.dart              # Root App widget
│   ├── app_consts.dart       # App-wide constants
│   ├── globals.dart          # Global variables and singletons
│   ├── main.dart             # App entry point
│   ├── extensions.dart       # Dart extension methods
│   └── shared_funcs.dart     # Shared utility functions
├── test/                     # Unit and widget tests
├── pubspec.yaml              # Flutter dependencies and project metadata
└── l10n.yaml                 # Localization configuration
```

