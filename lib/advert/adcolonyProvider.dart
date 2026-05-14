import 'dart:io';
import 'package:flutter/material.dart';

class AdcolonyProvider {
  bool adcolonyready = false;
  bool adcolonyreward = false;

  static List<String> get zones => Platform.isIOS
      ? ['vz5e0c866b461a4296b1', 'vz5e0c866b461a4296b1', 'vz8e7a2890d9d14e45bc']
      : [
          'vz9c4386eadee3475d85',
          'vz4bed309cad844555b3',
          'vzf201d4d3300d420b99'
        ];

  static String get adcolonyappid =>
      Platform.isIOS ? 'app50b1e16399444d259c' : 'appc29d105cd9a54d4091';

  AdcolonyProvider() {
    adcolonyinit();
  }

  adcolonyinit() {
    // AdColony.init(AdColonyOptions(adcolonyappid, '0', zones));
  }

  Future<bool> isloaded() async {
    return false;
  }

  void request() {
    // AdColony.request(zones[0], listener);
  }

  void show(Function? reward) {
    // AdColony.show();
  }

  Widget banner() {
    return Container();
  }
}
