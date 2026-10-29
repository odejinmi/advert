enum AdProviderType {
  google,
  unity,
  vungle,
  chartboost,
  levelplay,
}

extension AdProviderTypeExtension on AdProviderType {
  String get nameString {
    switch (this) {
      case AdProviderType.google:
        return 'Google';
      case AdProviderType.unity:
        return 'Unity';
      case AdProviderType.vungle:
        return 'Vungle';
      case AdProviderType.chartboost:
        return 'Chartboost';
      case AdProviderType.levelplay:
        return 'LevelPlay';
    }
  }
}
