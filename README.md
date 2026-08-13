# Advert SDK Plugin

A powerful, production-ready Flutter plugin for integrating **Google Mobile Ads** and **Unity Ads** with advanced revenue optimization features.

## Key Features

*   🚀 **High/Low Priority Waterfall**: Automatically prioritizes high-CPM ad placements and seamlessly falls back to lower tiers if they aren't available.
*   🔄 **Generic Ad Placements**: Create any number of custom placements (e.g., `Shop`, `GameOver`) for any ad format without modifying the SDK.
*   📦 **Unified Interface**: A single, clean API for Banner, Interstitial, Rewarded, and Native ads.
*   🎬 **Ad Sequences**: Built-in support for multi-ad sequences with customizable progress tracking UI.
*   📉 **Cross-Provider Rotation**: Intelligently cycles between Google and Unity to maximize fill rates.
*   📊 **Granular Event Reporting**: Automatically reports detailed events (e.g., `Freemoney_High`, `Banner_Low`) for precise analytics.

---

## Getting Started

### 1. Installation

Add `advert` to your `pubspec.yaml`:

```yaml
dependencies:
  advert:
    path: # path to your advert plugin
  get: ^4.7.3
```

### 2. Platform Setup

#### Android
Add your AdMob App ID to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR_ADMOB_APP_ID"/>
```

#### iOS
Add your AdMob App ID to `ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>YOUR_ADMOB_APP_ID</string>
```

---

## Usage

### Initialization

Initialize the SDK early in your app.

```dart
import 'package:advert/advert.dart';

final advert = Advert();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Basic initialization (uses default test units if testmode: true)
  await advert.initialize(testmode: true);
  
  runApp(MyApp());
}
```

### Advanced Configuration (Custom Unit IDs)

To use your own production Ad Units, configure the `Adsmodel` before initialization:

```dart
import 'package:advert/advert.dart';
import 'package:advert/model/adsmodel.dart';
import 'package:advert/model/google.dart';
import 'package:advert/model/unity.dart';

void initializeAds() async {
  // 1. Configure Google (AdMob) Units
  final googleConfig = Googlemodel()
    ..interstitialAdUnitId = ["high_inters_id"]
    ..interstitialAdUnitIdLow = ["low_inters_id"]
    ..rewardedAdUnitId = ["high_rewarded_id"]
    ..rewardedAdUnitIdLow = ["low_rewarded_id"]
    ..bannerAdUnitId = ["high_banner_id"]
    ..bannerAdUnitIdLow = ["low_banner_id"];

  // 2. Add Dynamic Placements (No SDK changes needed!)
  // This automatically creates a new placement named "giveaway"
  googleConfig.addRewardedPlacement(
    'giveaway', 
    high: ["your_high_placement_id"], 
    low: ["your_low_placement_id"]
  );

  // 3. Configure Unity Units
  final unityConfig = Unitymodel()
    ..gameId = "your_unity_game_id"
    ..rewardedVideoAdPlacementId = ["rewardedVideo"]
    ..interstitialVideoAdPlacementId = ["video"];

  // 4. Wrap in Adsmodel and Initialize
  final adsConfig = Adsmodel(googlemodel: googleConfig, unitymodel: unityConfig);
  await advert.initialize(testmode: false, adsmodel: adsConfig);
}
```

### Usage for Dynamic Placements

Once a placement is registered in the config, you can call it anywhere using the generic API:

```dart
// Showing the dynamic "giveaway" rewarded ad
advert.adsProv.showRewardedAd(
  type: 'giveaway', 
  onRewarded: () => print("Giveaway reward earned!"),
);

// It even works with ad sequences!
advert.adsProv.startAdSequence(
  context,
  total: 5,
  adType: 'giveaway',
  reason: "Watch 5 videos for a Mega Giveaway entry!",
  onComplete: () => print("Sequence complete"),
);
```

### High/Low Waterfall Logic

The SDK implements an automated waterfall for all ad types. When you request an ad, it will:
1.  Attempt to show the **High Placement** unit.
2.  Fallback to the **Low Placement** unit if High is not ready.
3.  (For specific types like `freemoney`) Fallback to an **Interstitial** if no rewarded ads are ready.

### Showing Ads

Access all ad methods through `advert.adsProv`.

#### Interstitial Ad
```dart
// Show default interstitial
advert.adsProv.showInterstitialAd();

// Show a specific custom placement
advert.adsProv.showInterstitialAd(type: 'LevelComplete');
```

#### Rewarded Ad
```dart
advert.adsProv.showRewardedAd(
  type: 'rewarded', // Optional custom type
  customData: {"user_id": "123"}, // For SSV
  onRewarded: () => print("Reward earned!"),
);
```

#### Native Ad
```dart
advert.adsProv.showNativeAd(context, type: 'MyPlacement');
```

#### Banner Ad
```dart
// Automatically uses the High -> Low waterfall
advert.adsProv.showBannerAd();
```

### Ad Sequences

Show a series of ads with a built-in progress dialog:

```dart
advert.adsProv.startAdSequence(
  context,
  total: 3,
  adType: 'freemoney', // Uses the full 3-tier waterfall
  reason: "Watch 3 videos to get 500 coins!",
  customData: {"goal": "coins"},
  onComplete: () {
    print("Sequence finished!");
  },
);
```

---

## Ad Types & Waterfalls Reference

| Type | Waterfall Behavior |
| :--- | :--- |
| Any Custom Name | Uses generic **High** → **Low** waterfall for that name. |
| `freemoney` | Special 3-tier: **High Rewarded** → **Low Rewarded** → **FM Interstitial** |
| `rewarded` | Standard: **High Rewarded** → **Low Rewarded** → **Rewarded Interstitial** |
| `interstitial` | **High Interstitial** → **Low Interstitial** |
| `banner` | **High Banner** → **Low Banner** |
| `native` | **High Native** → **Low Native** |

---

## Preloading

You can bulk-preload ads for all configured tiers at any time:

```dart
advert.adsProv.preloadAllAds();
```

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on our GitHub repository.
