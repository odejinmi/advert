
import 'dart:io';

class deviceallow {
  static allow() {
    if (Platform.isIOS || Platform.isAndroid) {
      return true;
    } else {
      return false;
    }
  }

  static apple() {
    if (Platform.isIOS) {
      return true;
    } else {
      return false;
    }
  }
}
