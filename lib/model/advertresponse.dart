import '../advert/device.dart';

class Advertresponse{
  /// A user readable message. If the transaction was not successful, this returns the
  /// cause of the error.
  String message;

  /// The status of the transaction. A successful response returns true and false
  /// otherwise
  bool status;

  Advertresponse.defaults()
      : message = deviceallow.allow()?"kindly check your network":"Kindly use a mobile device",
        status = false;

  Advertresponse.showing()
      : message = "advert showing",
        status = true;

  Advertresponse.loading()
      : message = "advert loading",
        status = true;

  Advertresponse.loaded()
      : message = "advert loaded",
        status = true;

  Advertresponse(
      {required this.message,
        required this.status,});
      // : assert();

  @override
  String toString() {
    return 'CheckoutResponse{message: $message, status: $status, }';
  }
}