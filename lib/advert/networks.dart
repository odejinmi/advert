import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';


class Networks extends GetxController {
  final _networkConnectivity = Connectivity();
  final _controller = StreamController.broadcast();
  Stream get myStream => _controller.stream;
  String string = '';
  var isonline = true.obs;
  var ipaddress = "".obs;

  void initialise() async {
    ConnectivityResult result = await _networkConnectivity.checkConnectivity();
    _checkStatus(result);
    _networkConnectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('www.google.com');
      ipaddress.value = result[0].address;
      isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      isOnline = false;
    }
    _controller.sink.add({result: isOnline});
  }

  void disposeStream() => _controller.close();

  Map _source = {ConnectivityResult.none: false};

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initialise();
    myStream.listen((source) {
      _source = source;
      // 1.
      if (_source.values.toList()[0]) {
        isonline.value = true;

      } else {
        isonline.value = false;
      }
      switch (_source.keys.toList()[0]) {
        case ConnectivityResult.mobile:
          string =
              _source.values.toList()[0] ? 'Mobile: Online' : 'Mobile: Offline';
          break;
        case ConnectivityResult.wifi:
          string =
              _source.values.toList()[0] ? 'WiFi: Online' : 'WiFi: Offline';
          break;
        case ConnectivityResult.none:
        default:
          string = 'Offline';
      }
      // 2.
      // setState(() {});
      // 3.
      // Snackbar.showMessage(string);
    });
  }
}
