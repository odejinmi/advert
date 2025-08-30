class Googlemodel {
  List<String> _screenUnitId = [];
  List<String> _videoUnitId = [];
  List<String> _rewardedinterstitialad = [];
  List<String> _nativeadUnitId = [];
  List<String> _banneradadUnitId = [];

  Googlemodel();

  bool get googleempty {
    return _screenUnitId.isEmpty &&
        _videoUnitId.isEmpty &&
        _rewardedinterstitialad.isEmpty &&
        _nativeadUnitId.isEmpty &&
        _banneradadUnitId.isEmpty;
  }

  List<String> get screenUnitId {
    return _screenUnitId;
  }

  set screenUnitId(value) {
    _screenUnitId = value;
  }

  List<String> get videoUnitId {
    return _videoUnitId;
  }

  set videoUnitId(value) {
    // Validate that the sdk has been initialized
    _videoUnitId = value;
  }

  List<String> get rewardedinterstitialad {
    return _rewardedinterstitialad;
  }

  set rewardedinterstitialad(value) {
    _rewardedinterstitialad = value;
  }

  List<String> get nativeadUnitId {
    return _nativeadUnitId;
  }

  set nativeadUnitId(value) {
    _nativeadUnitId = value;
  }

  List<String> get banneradadUnitId {
    return _banneradadUnitId;
  }

  set banneradadUnitId(value) {
    _banneradadUnitId = value;
  }
}
