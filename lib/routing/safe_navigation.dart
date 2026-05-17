import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension SafeGoRouterNavigation on BuildContext {
  void safePopOrGo(String fallbackLocation) {
    if (canPop()) {
      pop();
      return;
    }
    go(fallbackLocation);
  }
}
