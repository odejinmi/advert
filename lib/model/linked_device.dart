class LinkedDevice {
  final String deviceId;
  final String model;
  final String platform;
  final DateTime registeredAt;

  LinkedDevice({
    required this.deviceId,
    required this.model,
    required this.platform,
    required this.registeredAt,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'model': model,
    'platform': platform,
    'registeredAt': registeredAt.toIso8601String(),
  };

  factory LinkedDevice.fromJson(Map<String, dynamic> json) => LinkedDevice(
    deviceId: json['deviceId'],
    model: json['model'],
    platform: json['platform'],
    registeredAt: DateTime.parse(json['registeredAt']),
  );
}
