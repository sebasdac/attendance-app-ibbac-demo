import 'package:flutter/foundation.dart';
import '../../../core/services/birthday_cache_service.dart';
import '../../../core/services/birthday_notification_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  String? _welcomeMessage;

  AuthController({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository() {
    checkInitialSession();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get welcomeMessage => _welcomeMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isTeacher => _currentUser?.isTeacher ?? false;

  void consumeWelcomeMessage() {
    _welcomeMessage = null;
  }

  /// Check stored session on app startup
  Future<void> checkInitialSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.getCachedUser();
      if (_currentUser != null) {
        _triggerBirthdayCheckInBackground();
      }
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Perform login action
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email.trim(), password);
      final userName = _currentUser?.name;
      final displayName = (userName != null && userName.isNotEmpty)
          ? userName
          : (_currentUser?.email ?? 'Usuario');
      _welcomeMessage = '¡Bienvenido(a), $displayName!';
      _isLoading = false;
      notifyListeners();

      _triggerBirthdayCheckInBackground();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Hubo un problema al iniciar sesión';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Perform logout action
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authRepository.clearUserLocally();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _triggerBirthdayCheckInBackground() {
    Future.microtask(() async {
      try {
        await BirthdayCacheService().syncBirthdaysFromFirestore(
          isTeacher: isTeacher,
        );
        await BirthdayNotificationService().checkAndNotifyTodayBirthdays();
      } catch (_) {}
    });
  }
}
