import 'package:flutter/foundation.dart';
import '../../../core/services/birthday_cache_service.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../kids/data/models/kids_class_model.dart';
import '../../kids/data/repositories/kids_repository.dart';

class SettingsController extends ChangeNotifier {
  final AuthController authController;
  final KidsRepository _kidsRepository;
  final BirthdayCacheService _birthdayCacheService;

  bool _isLoading = true;
  List<CachedBirthdayMember> _todayBirthdayMembers = [];
  List<KidsClass> _classes = [];

  SettingsController({
    required this.authController,
    KidsRepository? kidsRepository,
    BirthdayCacheService? birthdayCacheService,
  })  : _kidsRepository = kidsRepository ?? KidsRepository(),
        _birthdayCacheService = birthdayCacheService ?? BirthdayCacheService() {
    loadData();
  }

  bool get isLoading => _isLoading;
  List<CachedBirthdayMember> get todayBirthdayMembers => _todayBirthdayMembers;
  List<KidsClass> get classes => _classes;
  UserModel? get currentUser => authController.currentUser;
  bool get isTeacher => authController.currentUser?.isTeacher ?? false;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cached = await _birthdayCacheService.getTodayBirthdayMembers();
      _todayBirthdayMembers = isTeacher
          ? cached.where((m) => m.type == 'kid').toList()
          : cached;
    } catch (e) {
      debugPrint('🚨 [SettingsController] Error loading birthdays: $e');
      _todayBirthdayMembers = [];
    }

    if (!isTeacher) {
      try {
        _classes = await _kidsRepository.fetchClasses();
      } catch (e) {
        debugPrint('🚨 [SettingsController] Error fetching classes: $e');
        _classes = [];
      }
    } else {
      _classes = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addClass(String name) async {
    final success = await _kidsRepository.addClass(name);
    if (success) {
      try {
        _classes = await _kidsRepository.fetchClasses();
      } catch (_) {}
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteClass(String id) async {
    final success = await _kidsRepository.deleteClass(id);
    if (success) {
      try {
        _classes = await _kidsRepository.fetchClasses();
      } catch (_) {}
      notifyListeners();
    }
    return success;
  }

  Future<void> syncBirthdays() async {
    await _birthdayCacheService.syncBirthdaysFromFirestore(
      isTeacher: isTeacher,
      forceSync: true,
    );
    await loadData();
  }

  Future<void> logout() async {
    await authController.logout();
  }
}
