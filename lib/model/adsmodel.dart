import 'package:advert/model/unity.dart';

import 'google.dart';

class Adsmodel{
  Googlemodel? googlemodel;
  Unitymodel? unitymodel;
  Adsmodel({
    this.googlemodel, this.unitymodel
});
  bool get adsempty {
    return googlemodel == null && unitymodel == null;
  }
}