# Reddit Reader

A production-grade, cross-platform mobile-friendly web app built with Flutter, featuring a dark theme, Reddit API integration, AI personalization, and ad support.

## Live Demo

**Web App:** https://hxeklrmdkj22.space.minimax.io

## Features

### Core Features
- **Posts Feed**: Browse Reddit posts with infinite scroll pagination
- **Post Details**: View full post content with images, text, and external links
- **Like System**: Like posts and persist favorites across sessions
- **Subreddit Selection**: Choose from 25+ built-in subreddits or enter custom ones
- **AI Personalization**: Reorder feed based on your liked posts (fake AI)
- **Pull-to-Refresh**: Refresh posts with a swipe gesture
- **Dark Theme**: Beautiful dark mode with Reddit orange accents

### Design System
- **Primary Color**: #0A0A0A (rich black background)
- **Surface Color**: #1A1A1A (cards, dialogs)
- **Accent Color**: #FF4500 (Reddit orange)
- **Card Design**: Rounded corners (12px), subtle elevation

### Animations
- Like button: Scale animation with color transition
- Post cards: Fade-in animation on load
- Navigation: Smooth slide transitions
- Loading states: Shimmer effect skeletons
- AI overlay: Pulsing brain animation

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── constants/
│   ├── app_constants.dart    # Colors, strings, dimensions
│   └── app_theme.dart        # Dark theme configuration
├── models/
│   └── post_model.dart       # Reddit post data model
├── services/
│   ├── reddit_service.dart   # Reddit API integration
│   ├── storage_service.dart  # SharedPreferences wrapper
│   └── ad_service.dart       # Ad platform integration
├── providers/
│   ├── posts_provider.dart   # Posts state management
│   └── settings_provider.dart # Settings state management
├── screens/
│   ├── posts_feed_screen.dart  # Main feed screen
│   ├── post_detail_screen.dart # Post detail view
│   └── settings_screen.dart     # Settings & preferences
└── widgets/
    ├── post_card.dart        # Post card component
    ├── shimmer_loading.dart   # Loading skeleton
    ├── empty_state.dart      # Empty/error states
    └── ai_personalization_overlay.dart # AI overlay
```

## Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd reddit_reader
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS (requires macOS)
flutter run -d ios
```

### Building for Production

```bash
# Web
flutter build web

# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Ad Integration (StartApp SDK)

### Android Configuration

To enable real StartApp ads on Android:

1. Add the dependency to `pubspec.yaml`:
```yaml
dependencies:
  startapp_sdk: ^1.0.1
```

2. Add your StartApp App ID to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.startapp.sdk.APPLICATION_ID"
    android:value="YOUR_STARTAPP_APP_ID" />
```

3. Initialize the SDK in `lib/services/ad_service.dart`:
```dart
import 'package:startapp_sdk/startapp_sdk.dart';

class AdService {
  StartAppSDK? _startApp;

  Future<void> init() async {
    _startApp = StartAppSDK();
    await _startApp!.initSdk(
      appId: 'YOUR_STARTAPP_APP_ID',
      returnAd: true,
    );
  }

  Future<void> showInterstitialAd() async {
    HapticFeedback.mediumImpact();
    await _startApp?.loadInterstitial();
  }
}
```

### Web Placeholder
On web, a placeholder banner is shown. For production web ads, integrate Google AdMob or another web ad network.

## Reddit API

The app uses Reddit's public JSON API:
- Endpoint: `https://www.reddit.com/r/{subreddit}.json?limit=25`
- Pagination: `?after={post_id}` for infinite scroll
- Rate limiting with exponential backoff
- Error handling for network issues

## Data Storage

All data is stored locally using SharedPreferences:
- Selected subreddit preference
- Liked post IDs
- AI personalization settings
- Trained posts count

**Privacy**: No data is sent to external servers. Everything stays on your device.

## Built-in Subreddits

The app includes 25 pre-populated subreddits:
all, askreddit, worldnews, technology, science, gaming, movies, music, art, funny, memes, pics, gifs, videos, programming, flutter, android, ios, javascript, python, todayilearned, news, politics, business, sports, aww

## Testing Checklist

- [x] App loads and fetches posts from default subreddit (r/all)
- [x] User can change subreddit from settings
- [x] Infinite scroll loads additional posts
- [x] Like button persists liked status across app restarts
- [x] AI Personalize reorders posts based on liked content
- [x] Banner ads appear on all screens (placeholder on web)
- [x] Interstitial ads trigger after every 5 posts
- [x] Dark theme is consistent across all screens
- [x] App runs without errors on flutter run -d chrome
- [ ] App runs without errors on flutter run -d android

## Configuration Files

### Android (android/app/build.gradle.kts)
- minSdk: 21
- targetSdk: latest
- multiDexEnabled: true

### Permissions (AndroidManifest.xml)
- INTERNET permission (required for API calls)

## Version

- **Version**: 1.0.0
- **Flutter**: 3.41.5
- **Dart**: 3.11.3

## Credits

- Content powered by Reddit API
- Built with Flutter
- Dark theme inspired by Reddit's redesign

## License

This project is for educational purposes. Content belongs to respective Reddit users and Reddit.
