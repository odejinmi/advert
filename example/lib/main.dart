import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:advert/advert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _advertPlugin = Advert();
  final banneradUnitId = Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/6300978111']
      : ['ca-app-pub-3940256099942544/2934735716'];

  get screenUnitId => Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/1033173712']
      : ['ca-app-pub-3940256099942544/4411468910'];

  final  _nativeadUnitId = Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/2247696110']
      : ['ca-app-pub-3940256099942544/3986624511'];

  final videoUnitId = Platform.isAndroid
  // ? 'ca-app-pub-3940256099942544/5224354917'
      ? ['ca-app-pub-3940256099942544/5224354917']
      : ['ca-app-pub-3940256099942544/1712485313'];

  // TODO: replace this test ad unit with your own ad unit.
  final adUnitId = Platform.isAndroid
      ? ['ca-app-pub-3940256099942544/5354046379']
      : ['ca-app-pub-3940256099942544/6978759866'];

  bool native = false;
  bool banner = false;
  @override
  void initState() {
    super.initState();
    Googlemodel googlemodel = Googlemodel()
    ..banneradadUnitId = banneradUnitId
    ..nativeadUnitId = _nativeadUnitId
    ..adUnitId = adUnitId
    ..videoUnitId = videoUnitId
    ..screenUnitId = screenUnitId;
    _advertPlugin.initialize(Adsmodel(googlemodel: googlemodel));
    // initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _advertPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(onPressed: (){
                _advertPlugin.adsProv.showads();
              }, child: const Text("show advert")),
              TextButton(onPressed: (){
                setState(() {
                  native = !native;
                });
              }, child: const Text("show native advert")),
              Visibility(
                visible: native,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320, // minimum recommended width
                    minHeight: 90, // minimum recommended height
                    maxWidth: 400,
                    maxHeight: 200,
                  ),
                  child: _advertPlugin.adsProv.shownativeads(),
                ),
              ),
              TextButton(onPressed: (){
                _advertPlugin.adsProv.showreawardads((){});
              }, child: const Text("show reward advert")),
              TextButton(onPressed: (){
                setState(() {
                  banner = !banner;
                });
              }, child: const Text("show banner advert")),
              Visibility(
                visible: banner,
                  child: _advertPlugin.adsProv.banner()),
            ],
          ),
        ),
      ),
    );
  }
  void showad(){
    print("native advert");

    // Small template
    final adContainer = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320, // minimum recommended width
        minHeight: 90, // minimum recommended height
        maxWidth: 400,
        maxHeight: 200,
      ),
      child: _advertPlugin.adsProv.shownativeads(),
    );

    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () { },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("My Advert"),
      content: adContainer,
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

  }
}
