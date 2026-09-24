import 'package:flutter/foundation.dart';
import '../../../core/services/birthday_cache_service.dart';
import '../data/models/kid_model.dart';
import '../data/models/kids_class_model.dart';
import '../data/repositories/kids_repository.dart';

class RegisterKidController extends ChangeNotifier {
  final KidsRepository _repository;

  bool _isLoading = false;
  bool _isLoadingKids = false;
  bool _dataLoaded = false;
  String? _errorMessage;
  String? _successMessage;

  List<KidsClass> _classes = [];
  List<KidModel> _kids = [];
  List<KidModel> _filteredKids = [];

  // Form State
  String _name = '';
  String _birthDay = '';
  String _comments = '';
  List<String> _selectedClasses = [];
  bool _isNew = false;
  bool _isEditing = false;
  KidModel? _selectedKid;

  // Filter State
  String _searchName = '';
  String _searchClass = '';

  RegisterKidController({KidsRepository? repository})
    : _repository = repository ?? KidsRepository() {
    loadClasses();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingKids => _isLoadingKids;
  bool get dataLoaded => _dataLoaded;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearErrorMessage() {
    _errorMessage = null;
  }

  void clearSuccessMessage() {
    _successMessage = null;
  }

  List<KidsClass> get classes => _classes;
  List<KidModel> get kids => _kids;
  List<KidModel> get filteredKids => _filteredKids;

  String get name => _name;
  String get birthDay => _birthDay;
  String get comments => _comments;
  List<String> get selectedClasses => _selectedClasses;
  bool get isNew => _isNew;
  bool get isEditing => _isEditing;
  KidModel? get selectedKid => _selectedKid;

  String get searchName => _searchName;
  String get searchClass => _searchClass;

  int get totalKidsCount => _kids.length;
  int get filteredKidsCount => _filteredKids.length;
  int get newKidsCount => _kids.where((k) => k.isNew).length;

  // Setters / Form mutators
  void setName(String val) {
    _name = val;
    notifyListeners();
  }

  void setComments(String val) {
    _comments = val;
    notifyListeners();
  }

  void setIsNew(bool val) {
    _isNew = val;
    notifyListeners();
  }

  void setSearchName(String val) {
    _searchName = val;
    _applyFilters();
    notifyListeners();
  }

  void setSearchClass(String val) {
    _searchClass = val;
    _applyFilters();
    notifyListeners();
  }

  /// Formats birthDay text as dd/mm/yyyy
  void setBirthDayFormatted(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 8) return;

    String result = digits;
    if (digits.length >= 3) {
      result = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    if (digits.length >= 5) {
      result =
          '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}';
    }

    _birthDay = result;
    notifyListeners();
  }

  void setBirthDay(String val) {
    _birthDay = val;
    notifyListeners();
  }

  bool validateDate(String date) {
    final regex = RegExp(r'^\d{2}\/\d{2}\/\d{4}$');
    return regex.hasMatch(date);
  }

  void toggleClassSelection(String className) {
    if (_selectedClasses.contains(className)) {
      _selectedClasses.remove(className);
    } else {
      _selectedClasses.add(className);
    }
    notifyListeners();
  }

  /// Fetch classes list from Firestore
  Future<void> loadClasses() async {
    try {
      _classes = await _repository.fetchClasses();
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch registered kids from Firestore
  Future<void> loadKids() async {
    _isLoadingKids = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _kids = await _repository.fetchKids();
      _applyFilters();
      _dataLoaded = true;
    } catch (e) {
      _errorMessage = 'Error al cargar los niños';
    } finally {
      _isLoadingKids = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    List<KidModel> result = List.from(_kids);

    if (_searchName.trim().isNotEmpty) {
      final query = _searchName.toLowerCase().trim();
      result = result
          .where((kid) => kid.name.toLowerCase().contains(query))
          .toList();
    }

    if (_searchClass.trim().isNotEmpty) {
      result = result
          .where((kid) => kid.classes.contains(_searchClass))
          .toList();
    }

    _filteredKids = result;
  }

  /// Save new kid or update existing kid
  Future<bool> saveKid() async {
    if (_name.trim().isEmpty ||
        _birthDay.trim().isEmpty ||
        _selectedClasses.isEmpty) {
      _errorMessage = 'Por favor, completa todos los campos requeridos';
      notifyListeners();
      return false;
    }

    if (!validateDate(_birthDay.trim())) {
      _errorMessage =
          'Por favor, ingresa una fecha válida en formato dd/mm/aaaa';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isEditing && _selectedKid != null) {
        final updatedKid = KidModel(
          id: _selectedKid!.id,
          name: _name.trim(),
          birthDay: _birthDay.trim(),
          classes: List.from(_selectedClasses),
          isKid: true,
          isNew: _isNew,
          comments: _comments.trim(),
        );
        await _repository.updateKid(updatedKid);
        _successMessage = 'Niño actualizado con éxito';
      } else {
        final newKid = KidModel(
          id: '',
          name: _name.trim(),
          birthDay: _birthDay.trim(),
          classes: List.from(_selectedClasses),
          isKid: true,
          isNew: _isNew,
          comments: _comments.trim(),
          createdAt: DateTime.now(),
        );
        await _repository.addKid(newKid);
        await BirthdayCacheService().addMemberToCache(
          name: _name.trim(),
          birthDay: _birthDay.trim(),
          type: 'kid',
        );
        _successMessage = 'Niño registrado con éxito';
      }

      clearForm();
      await loadKids();
      return true;
    } catch (e) {
      _errorMessage = 'Error al ${_isEditing ? "actualizar" : "registrar"}: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Prepare form for editing a kid
  void startEditing(KidModel kid) {
    _selectedKid = kid;
    _name = kid.name;
    _birthDay = kid.birthDay;
    _selectedClasses = List.from(kid.classes);
    _comments = kid.comments;
    _isNew = kid.isNew;
    _isEditing = true;
    notifyListeners();
  }

  /// Delete kid by ID
  Future<bool> deleteKid(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteKid(id);
      _successMessage = 'Niño eliminado con éxito';
      await loadKids();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear form state
  void clearForm() {
    _name = '';
    _birthDay = '';
    _comments = '';
    _selectedClasses = [];
    _isNew = false;
    _isEditing = false;
    _selectedKid = null;
    notifyListeners();
  }

  void clearFilters() {
    _searchName = '';
    _searchClass = '';
    _applyFilters();
    notifyListeners();
  }
}
