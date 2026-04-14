import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/child_profile/presentation/providers/child_profile_providers.dart';

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final notifier = RouterRefresh(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._ref) {
    _ref.listen(authSessionProvider, (previous, next) => notifyListeners());
    _ref.listen(childProfileProvider, (previous, next) => notifyListeners());
  }

  final Ref _ref;
}
