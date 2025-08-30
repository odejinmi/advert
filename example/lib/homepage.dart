import 'package:advert/advert/advert.dart';
import 'package:advert/model/advertresponse.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String _platformVersion = 'Unknown';
  final _advertPlugin = Advert();

  bool native = false;
  bool banner = false;
  @override
  void initState() {
    super.initState();
    _advertPlugin.initialize(testmode: true);
    // initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _advertPlugin.getPlatformVersion() ??
          'Unknown platform version';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  _advertPlugin.adsProv.showInterstitialAd();
                },
                child: const Text("show advert")),
            TextButton(
                onPressed: () {
                  setState(() {
                    native = !native;
                  });
                },
                child: const Text("show native advert")),
            Visibility(
              visible: native,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 320, // minimum recommended width
                  minHeight: 90, // minimum recommended height
                  maxWidth: 400,
                  maxHeight: 200,
                ),
                child: _advertPlugin.adsProv.showNativeAd(),
              ),
            ),
            TextButton(
                onPressed: () {
                  showreawardads(() {});
                },
                child: const Text("show reward advert")),
            TextButton(
                onPressed: () {
                  mutipleadvert(reward: () {});
                },
                child: const Text("show multiple reward advert")),
            TextButton(
                onPressed: () {
                  // Navigator.push(context,
                  //     MaterialPageRoute(
                  //         builder: (context) => ReusableInlineExample())
                  // );
                  setState(() {
                    banner = !banner;
                  });
                },
                child: Text("${banner ? 'Hide' : 'show'} banner advert")),
            Visibility(
                visible: banner, child: _advertPlugin.adsProv.showBannerAd()),
          ],
        ),
      ),
    );
  }

  void showad() {
    print("native advert");

    // Small template
    final adContainer = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320, // minimum recommended width
        minHeight: 90, // minimum recommended height
        maxWidth: 400,
        maxHeight: 200,
      ),
      child: _advertPlugin.adsProv.showNativeAd(),
    );

    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () {},
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

  int gm_advt = 0;

  Future<Advertresponse> showreawardads(Function reward) async {
    var customData = {"username": "", "platform": "", "type": ""};
    return await _advertPlugin.adsProv.showRewardedAd(reward, customData, 3);
  }

  Future<Advertresponse> mutipleadvert(
      {required Function reward, int max = 3}) async {
    return await showreawardads(() {
      if (gm_advt < max) {
        print("multiple advert $gm_advt");
        gm_advt += 1;
        setState(() {});
        return mutipleadvert(reward: reward);
      } else {
        print("multiple advert $gm_advt finished");
        gm_advt = 0;
        setState(() {});
        reward();
        return Advertresponse(message: "advert finished showing", status: true);
      }
    });
  }
}
