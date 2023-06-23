import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'bannerad.dart';

class BannerAdmob extends StatefulWidget {
  const BannerAdmob({Key? key}) : super(key: key);

  @override
  BannerAdmobState createState() => BannerAdmobState();
}

class BannerAdmobState extends State<BannerAdmob> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Get.find<Bannerad>().addispose();
  }

  @override
  void didUpdateWidget(covariant BannerAdmob oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    Get.find<Bannerad>().addispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      child: Get.find<Bannerad>().adWidget(),
    );
  }
}
