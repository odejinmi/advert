import 'package:advert/model/ad_provider_type.dart';
import 'package:advert/model/chartboost.dart';
import 'package:advert/model/levelplay.dart';
import 'package:advert/model/unity.dart';
import 'package:advert/model/vungle.dart';

import 'google.dart';

class Adsmodel{
  Googlemodel? googlemodel;
  Unitymodel? unitymodel;
  Vunglemodel? vunglemodel;
  Chartboostmodel? chartboostmodel;
  Levelplaymodel? levelplaymodel;

  /// Custom map to enable/disable specific providers
  Map<AdProviderType, bool>? enabledProviders;

  /// Custom priority/waterfall order for providers
  List<AdProviderType>? providerPriorityOrder;

  Adsmodel({
    this.googlemodel,
    this.unitymodel,
    this.vunglemodel,
    this.chartboostmodel,
    this.levelplaymodel,
    this.enabledProviders,
    this.providerPriorityOrder,
  });

  bool get adsempty {
    return googlemodel == null &&
        unitymodel == null &&
        vunglemodel == null &&
        chartboostmodel == null &&
        levelplaymodel == null;
  }
}