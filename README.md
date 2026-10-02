# WA Filter

**See WhatsApp messages from selected contacts/groups without ever opening WhatsApp.**

A floating overlay (like TrueCaller, or Facebook Messenger chat-heads) that intercepts
WhatsApp notifications and shows filtered messages on top of whatever app you're using.

---

## How it works

```
WhatsApp notification
       │
WaNotificationService (Kotlin – NotificationListenerService)
       │  EventChannel
Flutter NotificationService (Dart)
       │  filter check (your whitelist)
       ├──── [pass] ──→ stores in history ──→ HomeScreen > Messages tab
       │                       │
       │               FlutterOverlayWindow.shareData()
       │                       │
       └──────────────→  OverlayWidget (separate isolate)
                             floating card over all apps
```

**Platform:** Android only. iOS does not allow overlay windows or notification interception by third-party apps.

---

## Setup

### 1. Create a fresh Flutter project and copy files

```bash
flutter create --org com.example --project-name wa_filter wa_filter
cd wa_filter
```

Copy the files from this repo **on top of** the generated project, replacing:
- `pubspec.yaml`
- `lib/` (entire folder)
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/wa_filter/MainActivity.kt`
- Add: `android/app/src/main/kotlin/com/example/wa_filter/WaNotificationService.kt`

### 2. If your package name differs from `com.example.wa_filter`

- In both `.kt` files, change `package com.example.wa_filter` to your package.
- In `AndroidManifest.xml`, no change needed (uses `${applicationName}` / `${packageName}` placeholders).

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Build and run on a real Android device

```bash
flutter run --release   # Release build recommended (overlay needs real device)
```

> **Note:** The overlay and NotificationListenerService do not work on emulators.
> Use a physical Android device (Android 8+).

---

## First-run setup (in-app)

The app will walk you through two permission grants:

1. **Notification Access** → Settings → Apps → Special app access → Notification access → WA Filter ✓  
2. **Display Over Other Apps** → the app opens the settings page for you automatically.

After both grants the app starts listening.

---

## Usage

### Messages tab
- Real-time feed of filtered WhatsApp messages.
- Unread count badge, "Mark all read" banner, sweep-to-clear.

### Filters tab
- Add contact or group names exactly as they appear in WhatsApp.
  - 1-to-1 chat → sender's saved name (e.g. `Mom`, `Arjun`)
  - Group chat → the group name (e.g. `College Crew`)
- **Empty whitelist = ALL messages are shown.** Add at least one filter to narrow down.
- Delete a filter with the trash icon.

### Floating overlay
- Appears automatically when a filtered message arrives.
- **Minimise button (–)** → collapses to a draggable bubble with unread badge.
- **Close button (×)** → dismisses overlay until the next filtered message.
- **Clear** → wipes the overlay's in-session list (history stays in the main app).

---

## Caveats

| Concern | Detail |
|---|---|
| WhatsApp notification content | WhatsApp must have notifications **on**. The overlay reads the same text shown in your notification shade. |
| Message not captured | If WhatsApp's notification is grouped/stacked (many unread), the summary line may appear instead of the text. Open WhatsApp once to clear the stack. |
| Battery optimisation | Add WA Filter to your battery-unrestricted list so Android doesn't kill it. |
| Multi-account WhatsApp | The service listens on `com.whatsapp`. For WhatsApp Business, change `WA_PACKAGE` in `WaNotificationService.kt` to `com.whatsapp.w4b`. |

---

## Project structure

```
lib/
├── main.dart                 # App + overlay entry points
├── models/
│   └── wa_message.dart
├── services/
│   ├── filter_service.dart   # Whitelist (SharedPreferences)
│   └── notification_service.dart  # EventChannel bridge + overlay driver
├── screens/
│   ├── home_screen.dart
│   ├── permissions_screen.dart
│   ├── messages_tab.dart
│   └── filters_tab.dart
└── widgets/
    └── overlay_widget.dart   # Runs in overlay isolate

android/.../kotlin/
├── MainActivity.kt           # EventChannel + MethodChannel setup
└── WaNotificationService.kt  # NotificationListenerService
```

---

## Extending

- **WhatsApp Business:** change `WA_PACKAGE = "com.whatsapp.w4b"` in `WaNotificationService.kt`.
- **Quick-reply from overlay:** use the `RemoteInput` action on the `StatusBarNotification`. The `flutter_overlay_window` package's `overlayListener` stream can carry a reply intent back.
- **Notification sound:** add `flutter_local_notifications` and post a silent local notification when a filter matches.
