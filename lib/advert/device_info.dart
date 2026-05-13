import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'deviceId': androidInfo.id, // This is a unique identifier on Android
        'model': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'version': androidInfo.version.release,
      };
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'deviceId': iosInfo.identifierForVendor, // Unique identifier on iOS
        'model': iosInfo.model,
        'manufacturer': 'Apple',
        'version': iosInfo.systemVersion,
      };
    }
    return {
      'platform': 'unknown',
      'deviceId': 'unknown',
    };
  }

  Future<Map<String, dynamic>> getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }
}
