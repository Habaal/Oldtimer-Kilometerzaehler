import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ob die gesamte Erfassung global pausiert ist.
final trackingPausiertProvider = StateProvider<bool>((ref) => false);
