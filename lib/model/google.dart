
class Googlemodel {

  List _screenUnitId = [];
  List _videoUnitId = [];
  List _rewardedinterstitialad = [];
  List _nativeadUnitId = [];
  List _banneradadUnitId = [];

  Googlemodel();

  bool get googleempty {
    return _screenUnitId.isEmpty && _videoUnitId.isEmpty && _rewardedinterstitialad.isEmpty && _nativeadUnitId.isEmpty && _banneradadUnitId.isEmpty;
  }

  List get screenUnitId {
    return _screenUnitId;
  }

  set screenUnitId (value) {
    _screenUnitId = value;
  }

  List get videoUnitId {
    return _videoUnitId;
  }

  set videoUnitId (value) {
    // Validate that the sdk has been initialized
    _videoUnitId = value;
  }

  List get rewardedinterstitialad {
    return _rewardedinterstitialad;
  }


  set rewardedinterstitialad (value) {
    _rewardedinterstitialad = value;
  }

  List get nativeadUnitId {
    return _nativeadUnitId;
  }

  set nativeadUnitId (value) {
    _nativeadUnitId = value;
  }

  List get banneradadUnitId {
    return _banneradadUnitId;
  }

  set banneradadUnitId (value) {
    _banneradadUnitId = value;
  }
}