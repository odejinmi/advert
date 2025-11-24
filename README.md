# Advert Plugin

A Flutter plugin for seamlessly integrating various advertising networks into your applications. This plugin provides a unified interface for displaying banner, interstitial, and rewarded video ads from multiple providers, with more to come.

## Features

*   **Multiple Ad Networks**: Easily switch between and combine ad providers without changing your core application logic.
*   **Cross-Platform Support**: Works on both Android and iOS, with a web implementation in progress.
*   **Ad Caching**: Automatically preloads and caches ads for a smooth user experience.
*   **Reward Callbacks**: Implement rewarded video ads with custom callbacks to grant users in-app rewards.

## Getting Started

To use this plugin, add `advert` as a [dependency in your pubspec.yaml file](https://flutter.dev/docs/development/packages-and-plugins/using-packages).

### Example

```dart
import 'package:advert/advert.dart';

// Initialize the plugin
final advert = Advert();

// Show an interstitial ad
advert.showInterstitialAd();

// Show a rewarded ad and grant a reward
advert.showRewardedAd((reward) {
  print('User earned reward: $reward');
});
```

For more detailed examples, please refer to the `example` directory.

## Contributing

Contributions are welcome! If you have any feature requests, bug reports, or pull requests, please open an issue on our [GitHub repository](https://github.com/your-repo-url).
