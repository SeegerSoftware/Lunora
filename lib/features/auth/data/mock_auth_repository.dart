import 'package:uuid/uuid.dart';

import '../../../core/config/admin_config.dart';
import '../../../services/mock/lunora_mock_store.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({required LunoraMockStore store, Uuid? uuid})
    : _store = store,
      _uuid = uuid ?? const Uuid();

  final LunoraMockStore _store;
  final Uuid _uuid;

  @override
  Future<UserModel?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return _store.sessionUser;
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final user = _userFrom(email);
    _store.sessionUser = user;
    return user;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final user = _userFrom(email);
    _store.sessionUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  UserModel _userFrom(String email) {
    final normalized = email.trim().toLowerCase();
    final existing = _store.userByEmail(normalized);
    if (existing != null) return existing;

    final created = UserModel(
      id: _uuid.v4(),
      email: normalized,
      createdAt: DateTime.now(),
      selectedPlan: null,
      subscriptionStatus: SubscriptionStatus.none,
      isAdmin: AdminConfig.matchesAdminEmail(normalized),
    );
    _store.putUser(created);
    return created;
  }

}
