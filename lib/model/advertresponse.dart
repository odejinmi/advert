import '../advert/device.dart';

class Advertresponse{
  /// A user readable message. If the transaction was not successful, this returns the
  /// cause of the error.
  String message;

  /// The status of the transaction. A successful response returns true and false
  /// otherwise
  bool status;

  /// The ad provider that served or attempted to serve the ad (e.g., 'Google', 'Unity')
  String? provider;

  Advertresponse.defaults({this.provider})
      : message = deviceallow.allow()?"kindly check your network":"Kindly use a mobile device",
        status = false;

  Advertresponse.showing({this.provider})
      : message = "advert showing",
        status = true;

  Advertresponse.loading({this.provider})
      : message = "advert loading",
        status = true;

  Advertresponse.loaded({this.provider})
      : message = "advert loaded",
        status = true;

  Advertresponse(
      {required this.message,
        required this.status,
        this.provider,});

  @override
  String toString() {
    return 'Advertresponse{message: $message, status: $status, provider: $provider}';
  }
}