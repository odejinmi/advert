import 'dart:io';

// import 'package:chartboost/banner.dart';
import 'package:flutter/material.dart';

import '../event_reporter.dart';

class ChartboostBannerAdWidget extends StatelessWidget {
  final List<String> locations;
  final EventReporter reporter;

  const ChartboostBannerAdWidget({
    super.key,
    required this.locations,
    required this.reporter,
  });

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid || locations.isEmpty) {
      return const SizedBox.shrink();
    }

    final location = locations.first;
    debugPrint('Building Chartboost Banner ad widget for location: $location');

    // return ChartboostBanner(
    //   BannerAdSize.STANDARD,
    //   location,
    // );
    return const SizedBox.shrink();
  }
}
