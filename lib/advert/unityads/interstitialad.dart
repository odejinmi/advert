import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class Unityinterstitialad {
  var screenUnitId;
  Unityinterstitialad(this.screenUnitId, this._reporter);

  final EventReporter _reporter;

  final List<String> intersAd1 = [];
  int numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  bool _isloading = false;
  int currentIndex = 0;

  void createInterstitialAd({Function? show}) {
    print("Start Loading rewardedAd");
    if (currentIndex >= screenUnitId.length) {
      if(show != null){
        show();
      }
      return; 
    }
    if (_isloading) {
      return; 
    }
    _isloading = true;
    var adunitid = screenUnitId[currentIndex];
    UnityAds.load(
      placementId: adunitid,
      onComplete: (placementId) {
        debugPrint('Load Complete $placementId');
        _isloading = false;
        intersAd1.add(placementId);
        numInterstitialLoadAttempts = 0;
        currentIndex++;
        if (currentIndex < screenUnitId.length) {
          createInterstitialAd(); 
        }
        if (show != null) {
          show();
        }
      },
      onFailed: (placementId, error, message) {
          debugPrint('Load Failed $placementId: $error $message');
          _isloading = false;
          _reporter.reportEvent(
            event: AdEvent.failed,
            adProvider: 'Unity',
            adType: 'Interstitial',
            placementId: placementId,
            errorMessage: '$error: $message',
          );
          print("Failed to load rewarded ad: $placementId, error: $error");
          numInterstitialLoadAttempts += 1;
          if (numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createInterstitialAd();
          } else {
            currentIndex++;
            if (currentIndex < screenUnitId.length) {
              createInterstitialAd(); 
            }
          }
      },
    );
  }

  Advertresponse showAd(Function? onclick){
    if (intersAd1.isEmpty) {
      createInterstitialAd(show: () => showAd(onclick));
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      return Advertresponse.defaults();
    }
    UnityAds.showVideoAd(
      placementId: intersAd1[0],
      onComplete: (placementId) {
        debugPrint('Video Ad $placementId completed');
        _reporter.reportEvent(
          event: AdEvent.completed,
          adProvider: 'Unity',
          adType: 'Interstitial',
          placementId: placementId,
        );
        addispose(placementId);
      },
      onFailed: (placementId, error, message) {
        debugPrint('Video Ad $placementId failed: $error $message');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Unity',
          adType: 'Interstitial',
          placementId: placementId,
          errorMessage: '$error: $message',
        );
        addispose(placementId);
      },
      onStart: (placementId) {
        addispose(placementId);
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Unity',
          adType: 'Interstitial',
          placementId: placementId,
        );
        debugPrint('Video Ad $placementId started');
      },
      onClick: (placementId) {
        debugPrint('Video Ad $placementId click');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Unity',
          adType: 'Interstitial',
          placementId: placementId,
        );
        if (onclick != null) {
          onclick();
        }
      },
      onSkipped: (placementId) {
        debugPrint('Video Ad $placementId skipped');
        addispose(placementId);
      },
    );
    return Advertresponse.showing();
  }


  void addispose(String ad) {
    intersAd1.remove(ad);
    currentIndex--;
    createInterstitialAd(); 
  }
}
