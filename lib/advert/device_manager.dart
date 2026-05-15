import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/linked_device.dart';
import 'device_info.dart';

class DeviceManager {
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  
  // Mocking a remote list of devices
  final List<LinkedDevice> _mockDevices = [];

  DeviceManager() {
    // Adding the current device as a mock starting point
    _initializeMock();
  }

  Future<void> _initializeMock() async {
    final info = await _deviceInfoService.getDeviceInfo();
    _mockDevices.add(LinkedDevice(
      deviceId: info['deviceId'] ?? 'unknown',
      model: info['model'] ?? 'Unknown Model',
      platform: info['platform'] ?? 'Unknown',
      registeredAt: DateTime.now().subtract(const Duration(days: 1)),
    ));
  }

  /// Registers the current device
  Future<bool> registerCurrentDevice() async {
    try {
      final info = await _deviceInfoService.getDeviceInfo();
      final deviceId = info['deviceId'] ?? 'unknown';
      
      // Check if already exists in mock
      if (_mockDevices.any((d) => d.deviceId == deviceId)) {
        debugPrint('DeviceManager: Device $deviceId already registered.');
        return true;
      }

      final newDevice = LinkedDevice(
        deviceId: deviceId,
        model: info['model'] ?? 'Unknown Model',
        platform: info['platform'] ?? 'Unknown',
        registeredAt: DateTime.now(),
      );

      // In a real app, this would be an HTTP POST
      await Future.delayed(const Duration(seconds: 1)); 
      _mockDevices.add(newDevice);
      debugPrint('DeviceManager: Registered device $deviceId');
      return true;
    } catch (e) {
      debugPrint('DeviceManager: Error registering device: $e');
      return false;
    }
  }

  /// Gets a list of all linked devices
  Future<List<LinkedDevice>> getLinkedDevices() async {
    // In a real app, this would be an HTTP GET
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockDevices);
  }

  /// Removes a device by its ID
  Future<bool> removeDevice(String deviceId) async {
    try {
      // In a real app, this would be an HTTP DELETE
      await Future.delayed(const Duration(milliseconds: 800));
      _mockDevices.removeWhere((d) => d.deviceId == deviceId);
      debugPrint('DeviceManager: Removed device $deviceId');
      return true;
    } catch (e) {
      debugPrint('DeviceManager: Error removing device: $e');
      return false;
    }
  }
}
