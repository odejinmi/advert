# Advert SDK Integration Guide

This guide provides step-by-step instructions for integrating the `advert` SDK into your Flutter application.

## 1. Installation

Add `advert` to your `pubspec.yaml` file:

```yaml
dependencies:
  advert:
    path: ../advert # or use git/pub version
  get: ^4.6.6 # Required for state management
```

Run `flutter pub get` to install the dependencies.

---

## 2. Platform Configuration

### Android

1.  Open `android/app/src/main/AndroidManifest.xml`.
2.  Add your AdMob Application ID inside the `<application>` tag:

```xml
<manifest>
    <application>
        <!-- Sample AdMob App ID: ca-app-pub-3940256099942544~3347511713 -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="YOUR_ADMOB_APP_ID"/>
    </application>
</manifest>
```

### iOS

1.  Open `ios/Runner/Info.plist`.
2.  Add the `GADApplicationIdentifier` key with your AdMob App ID:

```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_ADMOB_APP_ID</string>
```

---

## 3. Initialization

Initialize the SDK early in your app lifecycle (e.g., in your main widget's `initState` or before `runApp`).

```dart
import 'package:advert/advert.dart';

final _advertPlugin = Advert();

@override
void initState() {
  super.initState();
  // Set testmode: true for development
  _advertPlugin.initialize(testmode: true);
}
```

---

## 4. Basic Ad Usage

Access ad functions through `_advertPlugin.adsProv`.

### Interstitial Ads
```dart
_advertPlugin.adsProv.showInterstitialAd();
```

### Rewarded Ads
Rewarded ads require custom data and a callback for when the user completes the ad.
```dart
_advertPlugin.adsProv.showRewardedAd(
  () {
    print("User earned reward!");
  },
  {"user_id": "123", "action": "unlock_level"}
);
```

### Banner Ads
Display a banner ad anywhere in your widget tree:
```dart
_advertPlugin.adsProv.showBannerAd()
```

### Native Ads
Native ads can be constrained to fit your UI:
```dart
SizedBox(
  height: 200,
  child: _advertPlugin.adsProv.showNativeAd(),
)
```

---

## 5. Advanced: Ad Sequences

The SDK supports "Ad Sequences" which show multiple ads in a row with a progress dialog, often used for higher rewards.

```dart
_advertPlugin.adsProv.startAdSequence(
  context,
  total: 3, // Number of ads to show
  adType: 'rewarded', // Type: 'mergeRewarded', 'rewarded', 'spinAndWin', etc.
  reason: "Watch 3 ads to earn Premium",
  customData: {"goal": "premium_upgrade"},
  onComplete: () {
    print("Sequence completed!");
  },
);
```

---

## 6. Ad Types Reference

| Type | Description |
| :--- | :--- |
| `rewarded` | Standard Google Rewarded Ad |
| `mergeRewarded` | Rotates between Unity and Google providers |
| `googleMergeRewarded` | Google-specific rewarded rotation |
| `rewardedInterstitial` | Google Rewarded Interstitial |
| `spinAndWin` | Specialized rewarded ad placement |
| `freemoney` | Specialized rewarded ad placement |

## Troubleshooting

- **SDK Not Initialized**: Ensure `initialize()` is called and awaited before calling any ad methods.
- **No Ads Filling**: Check that you've correctly added the `APPLICATION_ID` to your Android/iOS manifests. In development, always use `testmode: true`.
- **GetX Dependency**: This SDK uses `GetX` for internal state management. Ensure your app is compatible with GetX.
