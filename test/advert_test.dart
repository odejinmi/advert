import 'package:flutter_test/flutter_test.dart';
import 'package:advert/advert.dart';
import 'package:advert/advert_platform_interface.dart';
import 'package:advert/advert_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdvertPlatform
    with MockPlatformInterfaceMixin
    implements AdvertPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AdvertPlatform initialPlatform = AdvertPlatform.instance;

  test('$MethodChannelAdvert is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdvert>());
  });

  test('getPlatformVersion', () async {
    Advert advertPlugin = Advert();
    MockAdvertPlatform fakePlatform = MockAdvertPlatform();
    AdvertPlatform.instance = fakePlatform;

    expect(await advertPlugin.getPlatformVersion(), '42');
  });
}
