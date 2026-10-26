import 'package:advert/model/chartboost.dart';
import 'package:advert/model/unity.dart';
import 'package:advert/model/vungle.dart';

import 'google.dart';

class Adsmodel{
  Googlemodel? googlemodel;
  Unitymodel? unitymodel;
  Vunglemodel? vunglemodel;
  Chartboostmodel? chartboostmodel;

  Adsmodel({
    this.googlemodel,
    this.unitymodel,
    this.vunglemodel,
    this.chartboostmodel,
  });

  bool get adsempty {
    return googlemodel == null && unitymodel == null && vunglemodel == null && chartboostmodel == null;
  }
}