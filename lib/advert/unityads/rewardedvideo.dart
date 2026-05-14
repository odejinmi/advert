import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../../model/advertresponse.dart';
import '../event_reporter.dart';

class Rewardedvideo {
  var videoUnitId;
  Rewardedvideo(this.videoUnitId, this._reporter);

  final EventReporter _reporter;

  final List<String> intersAd1 = [];
  int numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  bool _isloading = false;
  int currentIndex = 0;

  void createInterstitialAd({Function? show}) {
    print("Start Loading rewardedAd");
    if (currentIndex >= videoUnitId.length) {
      if(show != null){
        show();
      }
      return; 
    }
    if (_isloading) {
      return; 
    }
    _isloading = true;
    var adunitid = videoUnitId[currentIndex];
    UnityAds.load(
      placementId: adunitid,
      onComplete: (placementId) {
        debugPrint('Load Complete $placementId');
        intersAd1.add(placementId);
        _isloading = false;
        numInterstitialLoadAttempts = 0;
        currentIndex++;
        if (currentIndex < videoUnitId.length) {
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
            adType: 'Rewarded',
            placementId: placementId,
            errorMessage: '$error: $message',
          );
          numInterstitialLoadAttempts += 1;
          if (numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createInterstitialAd();
          } else {
            currentIndex++;
            if (currentIndex < videoUnitId.length) {
              createInterstitialAd(); 
            }
          }
      },
    );
  }

  Advertresponse showAd(Function? rewarded, Function? onClicked){
    if (intersAd1.isEmpty) {
      createInterstitialAd(show: () => showAd(rewarded, onClicked));
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
          adType: 'Rewarded',
          placementId: placementId,
        );
        createInterstitialAd();
        if (rewarded != null) {
          rewarded();
        }
      },
      onFailed: (placementId, error, message) {
        debugPrint('Video Ad $placementId failed: $error $message');
        _reporter.reportEvent(
          event: AdEvent.failed,
          adProvider: 'Unity',
          adType: 'Rewarded',
          placementId: placementId,
          errorMessage: '$error: $message',
        );
        Future.delayed(Duration(seconds: 2), () {
          createInterstitialAd();
        });
        addispose(placementId);
      },
      onStart: (placementId) {
        addispose(placementId);
        _reporter.reportEvent(
          event: AdEvent.displayed,
          adProvider: 'Unity',
          adType: 'Rewarded',
          placementId: placementId,
        );
        debugPrint('Video Ad $placementId started');
      },
      onClick: (placementId) {
        debugPrint('Video Ad $placementId click');
        _reporter.reportEvent(
          event: AdEvent.clicked,
          adProvider: 'Unity',
          adType: 'Rewarded',
          placementId: placementId,
        );
        if (onClicked != null) {
          onClicked();
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

  static String get appId => Platform.isAndroid
      ? 'ca-app-pub-6117361441866120~5829948546'
      : 'ca-app-pub-6117361441866120~7211527566';
}
