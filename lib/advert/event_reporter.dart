import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'device_info.dart';

enum AdEvent {
  displayed,
  completed,
  failed,
  clicked,
}

class EventReporter {
  final String reportingUrl = "https://example.com/ad-events";
  final DeviceInfoService _deviceInfoService = DeviceInfoService();


  Future<void> reportEvent({
    required AdEvent event,
    required String adProvider,
    required String adType,
    String? placementId,
    String? errorMessage,
    Map<String, dynamic>? extraData,
  }) async {

    try {
      final deviceInfo = await _deviceInfoService.getDeviceInfo();
      final appInfo = await _deviceInfoService.getAppInfo();

      final Map<String, dynamic> payload = {
        'event': event.name,
        'adProvider': adProvider,
        'adType': adType,
        'placementId': placementId,
        'errorMessage': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
        'device': deviceInfo,
        'app': appInfo,
        'session_id': _getSessionId(),
        ...?extraData,
      };

      debugPrint('EventReporter: Sending event ${event.name} for $adProvider');
      
      final response = await http.post(
        Uri.parse(reportingUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('EventReporter: Event reported successfully');
      } else {
        debugPrint('EventReporter: Failed to report event. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('EventReporter: Error reporting event: $e');
    }
  }

  String _getSessionId() {
    // A simple session ID for the current app run. 
    // In a real app, this might be more complex or persisted.
    return hashCode.toString(); 
  }
}
