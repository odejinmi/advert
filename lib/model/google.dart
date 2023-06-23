
class Googlemodel {

  List _screenUnitId = [];
  List _videoUnitId = [];
  List _adUnitId = [];
  List _nativeadUnitId = [];
  List _banneradadUnitId = [];

  Googlemodel();

  bool get googleempty {
    return _screenUnitId.isEmpty && _videoUnitId.isEmpty && _adUnitId.isEmpty && _nativeadUnitId.isEmpty && _banneradadUnitId.isEmpty;
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

  List get adUnitId {
    return _adUnitId;
  }


  set adUnitId (value) {
    _adUnitId = value;
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