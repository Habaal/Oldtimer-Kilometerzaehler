import 'package:flutter_riverpod/flutter_riverpod.dart';

final trackingPausiertProvider =
    NotifierProvider<_TrackingPausiertNotifier, bool>(
  _TrackingPausiertNotifier.new,
);

class _TrackingPausiertNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}
