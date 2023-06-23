import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'advert_platform_interface.dart';

/// An implementation of [AdvertPlatform] that uses method channels.
class MethodChannelAdvert extends AdvertPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('advert');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
