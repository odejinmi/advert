# Advert SDK Plugin

A Flutter plugin for seamlessly integrating various advertising networks (Google Mobile Ads and Unity Ads) into your applications. This plugin provides a unified interface for displaying banner, interstitial, and rewarded video ads, with built-in support for ad sequences and progress tracking.

## Features

*   **Multiple Ad Networks**: Integrated support for Google Mobile Ads and Unity Ads.
*   **Unified Interface**: Simple API to show ads from different providers using a single manager.
*   **Ad Sequences**: Easily show multiple ads in a row (e.g., "Watch 3 ads to earn reward") with built-in progress dialogs.
*   **Cross-Platform**: Supports Android and iOS.
*   **State Management**: Uses GetX for reactive ad status tracking.

---

## Getting Started

### 1. Installation

Add `advert` to your `pubspec.yaml`:

```yaml
dependencies:
  advert:
    path: # path to your advert plugin
  get: ^4.6.6
```

### 2. Platform Setup

#### Android
Add your AdMob App ID to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

#### iOS
Add your AdMob App ID to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

---

## Usage

### Initialization

Initialize the SDK early in your app (e.g., in `main.dart` or your root widget).

```dart
import 'package:advert/advert.dart';

final advert = Advert();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await advert.initialize(testmode: true);
  runApp(MyApp());
}
```

### Showing Ads

Access ad methods through `advert.adsProv`.

#### Interstitial Ad
```dart
advert.adsProv.showInterstitialAd();
```

#### Rewarded Ad
```dart
advert.adsProv.showRewardedAd(
  () => print("Reward earned!"),
  {"user_id": "user123"}
);
```

#### Banner Ad (Widget)
```dart
Column(
  children: [
    Expanded(child: MyContent()),
    advert.adsProv.showBannerAd(),
  ],
)
```

### Ad Sequences

Show a series of ads with a progress dialog:

```dart
advert.adsProv.startAdSequence(
  context,
  total: 3,
  adType: 'rewarded',
  reason: "Watch 3 ads to unlock premium feature",
  onComplete: () {
    print("Sequence finished! Granting premium.");
  },
);
```

---

## Ad Types Reference

| Type | Description |
| :--- | :--- |
| `rewarded` | Standard Google Rewarded Ad |
| `mergeRewarded` | Rotates between Unity and Google |
| `rewardedInterstitial` | Google Rewarded Interstitial |
| `spinAndWin` | Specialized rewarded placement |

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our GitHub repository.
