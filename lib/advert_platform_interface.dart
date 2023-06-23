import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'advert_method_channel.dart';

abstract class AdvertPlatform extends PlatformInterface {
  /// Constructs a AdvertPlatform.
  AdvertPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdvertPlatform _instance = MethodChannelAdvert();

  /// The default instance of [AdvertPlatform] to use.
  ///
  /// Defaults to [MethodChannelAdvert].
  static AdvertPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdvertPlatform] when
  /// they register themselves.
  static set instance(AdvertPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
