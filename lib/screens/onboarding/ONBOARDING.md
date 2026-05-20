# Notification Manager — Onboarding Flow Documentation

**App:** WeStack Notification Manager
**Package:** `com.example.notification_manager` (to be updated)
**Platform:** Android only
**State Management:** ValueNotifier (controller pattern)
**File Pattern:** Each screen has 2 files — `*_screen.dart` (UI) and `*_controller.dart` (logic)

---

## Theme

| Token          | Value       | Usage                              |
|----------------|-------------|-------------------------------------|
| Primary        | `#2AAEA1`   | Buttons, titles, active states      |
| Gradient End   | `#2FC0B1`   | Button gradient end                 |
| Accent         | `#DBEEEB`   | Borders, light backgrounds, glow    |
| Support        | `#FCFEFF`   | Scaffold background                 |

All buttons use a `LinearGradient([#2AAEA1, #2FC0B1])` with `BorderRadius.circular(16)` and height 56.
Disabled buttons use `Colors.grey.shade300` gradient with grey text.

---

## Flow

```
Welcome → Choose Apps → Permissions → Dashboard (main app)
```

All transitions use `Navigator.pushReplacement` (no back navigation in onboarding).

---

## Screen 1: Welcome Screen

**Files:** `screens/onboarding/welcome/welcome_screen.dart`, `welcome_controller.dart`

### UI Layout (top → bottom)

1. **Spacer** (flex: 2)
2. **Marquee Icon Animation** — 5 social media icons orbiting in a horizontal elliptical path
3. **Title** — "Manage all your notifications" (28px, w800, centered)
4. **Description** — RichText with bold "Notification Reader" + backup services text
5. **Disclaimer** — Terms of Use incompatibility notice (13px, grey)
6. **Spacer** (flex: 3)
7. **Accept Button** — gradient, full width, navigates to Choose Apps screen
8. **Terms & Conditions** — teal underlined link

### Marquee Animation Details

- **Controller** manages `AnimationController` (8s duration, infinite repeat)
- **5 PNG icon slots** in `iconPaths` array — currently: WhatsApp, Instagram, YouTube, Facebook, TikTok
- Icons orbit on a **horizontal ellipse**: wide X spread (`cos`), minimal Y wobble (`sin * 0.08`)
- **3D depth effect**: icons scale 0.55→1.0 and opacity 0.3→1.0 based on depth
- **Painter's algorithm**: sorted by depth so front icons render on top
- **Marquee dimensions**: `width: 300`, `height: 100`, `iconSize: 82.5`, orbit spread `0.38`

### Background Glow

- 3 overlapping soft `_accent` colored blobs at different positions/sizes/opacities
- Creates a random organic light glow behind the icons (not a perfect circle)

### Icon Bubbles

- White circle with `_accent` border (2px)
- `Image.asset()` with `errorBuilder` fallback to a teal notification icon
- Padding: 16px inside bubble

### Navigation

- Accept button → `Navigator.pushReplacement` → `ChooseAppsScreen`

---

## Screen 2: Choose Apps Screen

**Files:** `screens/onboarding/choose_apps/choose_apps_screen.dart`, `choose_apps_controller.dart`

### UI Layout (top → bottom)

1. **Header** — "Choose apps" title + "X of Y selected" subtitle + "All" toggle (circular checkbox)
2. **Info bar** — "Selected apps' notifications will be saved." on light accent background
3. **Search bar** — TextField with search icon, rounded, light grey fill
4. **App list** — Scrollable ListView of installed apps with icon, name, circular checkbox
5. **WhatsApp access cards** — Conditional cards above button (see below)
6. **Continue Setup button** — Disabled (grey) when 0 selected, gradient when 1+ selected

### Controller: App Loading & Sorting

- Uses `installed_apps` package: `InstalledApps.getInstalledApps(excludeSystemApps: true, excludeNonLaunchableApps: true, withIcon: true)`
- Each app becomes an `AppItem` with `packageName`, `appName`, `icon` (Uint8List), `isSelected`, `isWhatsApp`, `isDefaultApp`

**Sort order (priority):**
1. WhatsApp / WhatsApp Business (always top)
2. Default trending apps (pre-selected)
3. All other apps (alphabetical)

### Default Selected Apps (pre-checked on load)

```
com.whatsapp, com.whatsapp.w4b,
org.telegram.messenger, com.facebook.orca, com.Slack, com.discord,
com.viber.voip, com.google.android.apps.messaging,
com.instagram.android, com.snapchat.android, com.zhiliaoapp.musically,
com.twitter.android, com.facebook.katana, com.linkedin.android,
com.pinterest, com.reddit.frontpage, com.google.android.youtube
```

### Toggle Logic

- **Individual toggle**: tap row → flip `isSelected` → update count → refresh WhatsApp access
- **All toggle**: if all selected → deselect all; if not → select all
- All toggle circle: empty by default, filled teal with check when all selected

### Search

- Live filter on `allApps` by `appName.toLowerCase().contains(query)`
- Empty query → show all

### WhatsApp Folder Access Feature

**Appears when:** WhatsApp or WhatsApp Business is in the selected apps list.

**Card design:**
- Pink/red warning background when not granted, green accent when granted
- Shows WhatsApp icon, name, description, and Allow/Granted button
- Separate card per WhatsApp variant (both can appear simultaneously)

**Flow:**
1. Tap "Allow" → opens SAF (Storage Access Framework) folder picker
2. SAF pre-navigates to `Android/media/com.whatsapp/WhatsApp` (or WhatsApp Business equivalent)
3. User taps "USE THIS FOLDER" → system confirmation dialog → Allow
4. URI permission persisted via `takePersistableUriPermission` (survives reboots)
5. On app resume → recheck access → card updates to "Granted"

**Native methods (MethodChannel):**
- `hasWhatsAppFolderAccess(packageName)` — checks `persistedUriPermissions` for matching URI
- `requestWhatsAppFolderAccess(packageName)` — opens `ACTION_OPEN_DOCUMENT_TREE` with initial URI pointing to WhatsApp media folder

### On Confirm

1. Filters selected apps
2. Maps to `SelectedAppModel` (packageName, appName, icon)
3. Saves to Hive via `HiveService.instance.saveSelectedApps()`
4. Navigates to PermissionScreen

### WidgetsBindingObserver

- `didChangeAppLifecycleState(resumed)` → rechecks WhatsApp folder access

---

## Screen 3: Permission Screen

**Files:** `screens/onboarding/permissions/permission_screen.dart`, `permission_controller.dart`

### UI Layout (top → bottom)

1. **Header** — "Permissions" title + "X of Y enabled" subtitle
2. **Info bar** — "Please enable these permissions..." on light accent background
3. **Permission cards** — Scrollable list of 2-3 permission cards
4. **Continue button** — Disabled (grey) until all permissions granted

### Permission Cards (dynamic)

Cards are built dynamically based on device capabilities:

#### Card 1: Background Autostart (CONDITIONAL)

**Shown only on supported OEMs:** Xiaomi, Redmi, POCO, Oppo, Realme, OnePlus, Vivo, iQOO, Huawei, Honor, Asus, Letv, LeEco, Meizu, Tecno, Infinix

**NOT shown on:** Samsung, Google Pixel, stock Android, emulators, or any device where the OEM security package is not installed.

**Detection logic (native Kotlin):**
1. Check `Build.MANUFACTURER` against known OEM set
2. Verify OEM security package is installed via `packageManager.getPackageInfo()`
3. Verify specific autostart activity resolves via `intent.resolveActivity()`
4. All 3 must pass → card shown

**On Allow tap:**
- Opens OEM-specific autostart settings page (e.g., `com.miui.permcenter.autostart.AutoStartManagementActivity` for Xiaomi)
- Sets `_autostartVisited = true` (no API to verify actual toggle)
- On resume → marks as granted

**Supported OEM intents:**
- Xiaomi: `com.miui.securitycenter`
- Oppo: `com.coloros.safecenter`
- Realme: `com.oplus.safecenter`
- Vivo: `com.vivo.permissionmanager`
- Huawei: `com.huawei.systemmanager`
- OnePlus: `com.oneplus.security`
- Asus: `com.asus.mobilemanager`
- Letv: `com.letv.android.letvsafe`
- Meizu: `com.meizu.safe`
- Tecno/Infinix: `com.transsion.phonemanager`

#### Card 2: Notification Access (ALWAYS SHOWN)

**What it does:** Enables `NotificationListenerService` — allows app to read all device notifications.

**On Allow tap:**
- Opens `Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS`
- No system dialog exists — must toggle in settings
- On resume → checks `enabled_notification_listeners` in `Settings.Secure` for our component

**Verification (native Kotlin):**
```kotlin
Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
// Check if our ComponentName is in the flat string
```

#### Card 3: Notifications / POST_NOTIFICATIONS (ALWAYS SHOWN)

**What it does:** Allows app to send notifications to the user (Android 13+ requirement).

**On Allow tap:**
1. First tap → shows **system permission dialog** via `Permission.notification.request()`
2. If permanently denied → opens app settings via `openAppSettings()`
3. On resume → rechecks `Permission.notification.status`

**States:** `notRequested` → `granted` or `permanentlyDenied`

### Card UI Design

- White card with rounded corners (16px), light border
- Granted cards: teal border tint
- Left: colored icon container (40x40)
- Center: title (16px, w600) + description
- Right: gradient "Allow" button OR teal "Allowed" chip with check icon
- `AnimatedContainer` for smooth state transitions

### Continue Button

- Disabled (grey gradient + grey text) until ALL shown permissions are granted
- Enabled → teal gradient, navigates to Dashboard

### WidgetsBindingObserver

- `didChangeAppLifecycleState(resumed)` → rechecks all permission statuses
- Critical for autostart and notification access which redirect to external settings

---

## Native Layer (Android)

### Files

| File | Location | Purpose |
|------|----------|---------|
| `MainActivity.kt` | `android/app/src/main/kotlin/.../` | MethodChannel handlers for all permissions + WhatsApp SAF |
| `NotificationListener.kt` | Same directory | `NotificationListenerService` implementation |

### MethodChannel: `com.example.notification_manager/permissions`

| Method | Args | Returns | Used By |
|--------|------|---------|---------|
| `isAutostartAvailable` | — | `bool` | Permission screen init |
| `openAutostartSettings` | — | `bool` | Permission Allow tap |
| `isNotificationListenerEnabled` | — | `bool` | Permission status check |
| `openNotificationListenerSettings` | — | `bool` | Permission Allow tap |
| `hasWhatsAppFolderAccess` | `{packageName}` | `bool` | Choose Apps WhatsApp card |
| `requestWhatsAppFolderAccess` | `{packageName}` | `bool` | Choose Apps Allow tap |

### AndroidManifest.xml Additions

**Permissions (before `<application>`):**
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

**Service (inside `<application>`):**
```xml
<service
    android:name=".NotificationListener"
    android:label="Notification Manager"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    android:exported="false">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

---

## Database Layer

### Files

| File | Purpose |
|------|---------|
| `hive_service.dart` | Singleton Hive CRUD service for selected apps |
| `pref_service.dart` | Singleton SharedPreferences service for app config flags |

### Model: `SelectedAppModel`

```dart
@HiveType(typeId: 0)
class SelectedAppModel extends HiveObject {
  @HiveField(0) String packageName;
  @HiveField(1) String appName;
  @HiveField(2) Uint8List? icon;
}
```

### HiveService API

| Method | Purpose |
|--------|---------|
| `init()` | Register adapter + open box |
| `saveSelectedApps(List)` | Clear + save all (bulk) |
| `addApp(model)` | Upsert single app |
| `getSelectedApps()` | Get all saved apps |
| `getApp(packageName)` | Get single app |
| `isAppSaved(packageName)` | Check existence |
| `removeApp(packageName)` | Delete single |
| `clearAll()` | Delete all |

**Box name:** `selected_apps`
**Key strategy:** `packageName` as key (via `box.put`)

### Init in main.dart

```dart
await Hive.initFlutter();
await HiveService.instance.init();
```

Requires `flutter pub run build_runner build` to generate `hive_service.g.dart`.

---

## Dependencies

```yaml
# pubspec.yaml
dependencies:
  installed_apps: ^2.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  permission_handler: ^11.3.0
  shared_preferences: ^2.3.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.0
```

```groovy
// android/app/build.gradle (after flutter block)
dependencies {
    implementation("androidx.documentfile:documentfile:1.0.1")
}
```

---

## File Structure

```
lib/
├── main.dart
├── database/
│   ├── hive_service.dart
│   └── pref_service.dart
└── screens/
    ├── onboarding/
    │   ├── welcome/
    │   │   ├── welcome_screen.dart
    │   │   └── welcome_controller.dart
    │   ├── choose_apps/
    │   │   ├── choose_apps_screen.dart
    │   │   └── choose_apps_controller.dart
    │   └── permissions/
    │       ├── permission_screen.dart
    │       └── permission_controller.dart
    └── dashboard/
        └── dashboard_screen.dart

android/app/src/main/
├── AndroidManifest.xml (with additions)
└── kotlin/com/example/notification_manager/
    ├── MainActivity.kt
    └── NotificationListener.kt

assets/
└── icons/
    ├── whatsapp.png
    ├── instagram.png
    ├── youtube.png
    ├── facebook.png
    └── tiktok.png
```

---

## SharedPreferences Layer

### File: `lib/database/pref_service.dart`

Singleton service initialized in `main.dart` before `runApp`.

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `onboarding_done` | `bool` | `false` | Set `true` after Permission screen Continue tap |

### API

| Method | Returns | Purpose |
|--------|---------|---------|
| `init()` | `Future<void>` | Initialize SharedPreferences instance |
| `isOnboardingDone` | `bool` | Check if onboarding completed |
| `setOnboardingDone(bool)` | `Future<void>` | Save onboarding flag |

---

## App Routing (main.dart)

### Init sequence

```
WidgetsFlutterBinding.ensureInitialized()
  → Hive.initFlutter()
  → HiveService.instance.init()
  → PrefService.instance.init()
  → runApp()
```

### Home screen decision

```dart
home: PrefService.instance.isOnboardingDone
    ? const DashboardScreen()
    : const WelcomeScreen(),
```

- **First launch:** `isOnboardingDone = false` → WelcomeScreen → onboarding flow
- **Subsequent launches:** `isOnboardingDone = true` → DashboardScreen directly

### When flag is set

Permission screen → Continue button tap → `PrefService.instance.setOnboardingDone(true)` → navigate to DashboardScreen

