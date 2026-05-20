# Notification Manager

A comprehensive Flutter application for managing notifications across multiple platforms with advanced filtering, app detection, and media viewing capabilities.

## 📋 Features

- **Cross-Platform Support**: Native support for Android, iOS, macOS, Windows, Linux, and Web
- **Notification Management**: Organize and manage notifications efficiently
- **App Detection**: Installed apps cache for quick app identification
- **Media Viewing**: View photos and videos with Photo View and Video Player
- **Local Storage**: Persistent data storage using Hive database
- **Permissions Handling**: Comprehensive permission management for all platforms
- **Device Information**: Access device-specific information
- **URL Launcher**: Support for opening URLs from notifications
- **Clipboard Management**: Copy notification content to clipboard
- **Native Splash Screen**: Custom splash screens for iOS and Android
- **Material Design**: Modern Material Design UI with custom color scheme
- **Onboarding**: Welcome screen with app introduction

## 🚀 Getting Started

### Prerequisites

- Flutter SDK: ^3.8.1 or higher
- Dart: ^3.8.1 or higher
- For Android: Android SDK (API level 21+)
- For iOS: Xcode and iOS deployment target 11.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd notification_manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive type adapters**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
notification_manager/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── database/              # Database layer (Hive, SharedPreferences)
│   ├── screens/               # UI screens and views
│   │   ├── home/              # Home screen and dashboard
│   │   └── onboarding/        # Welcome and setup screens
│   ├── services/              # Business logic services
│   │   ├── notification_engine.dart
│   │   └── installed_apps_cache.dart
│   └── ... (additional Dart files)
├── android/                   # Android native code
├── ios/                       # iOS native code
├── macos/                     # macOS native code
├── windows/                   # Windows native code
├── linux/                     # Linux native code
├── web/                       # Web platform files
├── assets/                    # Images, icons, and splash screens
├── test/                      # Unit and widget tests
├── pubspec.yaml               # Project dependencies
└── README.md                  # This file
```

## 🔧 Dependencies

### Core Dependencies

- **flutter**: Flutter framework
- **provider**: ^6.1.5+1 - State management
- **hive** & **hive_flutter**: ^1.1.0 - Local database
- **shared_preferences**: ^2.5.3 - Simple key-value storage

### Platform & Device

- **permission_handler**: ^12.0.1 - Permission management
- **device_info_plus**: ^12.4.0 - Device information
- **installed_apps**: ^2.1.1 - Detect installed applications
- **path_provider**: ^2.1.5 - File system paths

### Media & UI

- **video_player**: ^2.11.1 - Video playback
- **video_thumbnail**: ^0.5.6 - Video thumbnails
- **photo_view**: ^0.15.0 - Photo viewing with zoom
- **google_fonts**: ^8.0.2 - Google Fonts support

### Utilities

- **url_launcher**: ^6.3.2 - Launch URLs
- **clipboard**: ^3.0.14 - Clipboard operations
- **crypto**: ^3.0.7 - Cryptographic functions
- **flutter_native_splash**: ^2.4.7 - Native splash screens
- **flutter_launcher_icons**: ^0.13.1 - App icons

### Dev Dependencies

- **flutter_test**: Testing framework
- **flutter_lints**: Linting rules
- **build_runner**: ^2.4.13 - Code generation
- **hive_generator**: ^2.0.1 - Hive type adapter generation

## 🎨 Design

- **Primary Color**: Teal (#2AAEA1)
- **Design System**: Material Design
- **Font**: Google Fonts support for typography
- **Responsive**: Adapts to different screen sizes

## 🏗️ Building for Release

### Android
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### macOS
```bash
flutter build macos --release
```

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

## 🧪 Testing

Run all tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

## 📝 Code Generation

This project uses Hive with type adapters. To regenerate type adapters after model changes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🔐 Permissions

The app requests the following permissions:

- **Android/iOS**: Notification access, app installation detection
- **macOS/Windows/Linux**: File system access where needed

Permissions are handled gracefully with fallbacks if not granted.

## 🐛 Troubleshooting

### Build Issues
- Clear build cache: `flutter clean`
- Get fresh dependencies: `flutter pub get`
- Regenerate code: `flutter pub run build_runner clean` then `flutter pub run build_runner build`

### Running Issues
- Check Flutter setup: `flutter doctor`
- Verify Android SDK path is set correctly
- For iOS, ensure pods are updated: `cd ios && pod update && cd ..`

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📧 Support

For issues, bug reports, or feature requests, please create an issue in the repository.

---

**Last Updated**: May 2026
