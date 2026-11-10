import 'package:flutter/widgets.dart';

/// Content of the right details panel (expanded) or the details sheet (medium,
/// compact): step, source and memory details (28.6, 28.7).
class DetailsController extends ValueNotifier<Widget?> {
  DetailsController() : super(null);
  void show(Widget details) => value = details;
  void close() => value = null;
}
