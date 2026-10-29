import 'package:chartboost_flutter/chartboost_flutter.dart';
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
    if (locations.isEmpty) {
      return const SizedBox.shrink();
    }

    final location = locations.first;
    debugPrint('Building Chartboost Banner ad widget for location: $location');

    return ChartboostBannerView(
      location: location,
      size: ChartboostBannerSize.standard,
    );
  }
}
