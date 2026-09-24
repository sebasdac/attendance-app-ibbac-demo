import 'package:flutter/foundation.dart';
import '../../../core/services/birthday_cache_service.dart';
import '../data/models/person_model.dart';
import '../data/repositories/people_repository.dart';

class PeopleController extends ChangeNotifier {
  final PeopleRepository _repository;

  PeopleController({PeopleRepository? repository})
    : _repository = repository ?? PeopleRepository();

  List<PersonModel> _allPeople = [];
  List<PersonModel> _filteredPeople = [];
  bool _isLoadingPeople = false;
  bool _isSaving = false;
  String? _deletingId;
  String _searchQuery = '';
  String? _errorMessage;
  String? _successMessage;
  PersonModel? _editingPerson;
  bool _dataLoaded = false;

  List<PersonModel> get people => _filteredPeople;
  bool get isLoadingPeople => _isLoadingPeople;
  bool get isSaving => _isSaving;
  String? get deletingId => _deletingId;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  PersonModel? get editingPerson => _editingPerson;
  bool get isEditing => _editingPerson != null;
  bool get dataLoaded => _dataLoaded;

  /// Fetches people list from Firestore
  Future<void> fetchPeople() async {
    _isLoadingPeople = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allPeople = await _repository.getPeople();
      _dataLoaded = true;
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Error al cargar las personas: $e';
    } finally {
      _isLoadingPeople = false;
      notifyListeners();
    }
  }

  /// Sets search query and updates filtered list
  void filterPeople(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.trim().isEmpty) {
      _filteredPeople = List.from(_allPeople);
    } else {
      final normalizedQuery = _removeDiacritics(_searchQuery.toLowerCase());
      _filteredPeople = _allPeople.where((person) {
        final normalizedName = _removeDiacritics(person.name.toLowerCase());
        final phone = person.phone;
        return normalizedName.contains(normalizedQuery) ||
            phone.contains(normalizedQuery);
      }).toList();
    }
  }

  /// Registers a new person in Firestore
  Future<bool> registerPerson({
    required String name,
    required String phone,
    required String birthDay,
    required bool isNew,
  }) async {
    final validationError = _validateInputs(name, phone, birthDay);
    if (validationError != null) {
      _errorMessage = validationError;
      _successMessage = null;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.addPerson(
        name: name,
        phone: phone,
        birthDay: birthDay,
        isNew: isNew,
      );
      await BirthdayCacheService().addMemberToCache(
        name: name,
        birthDay: birthDay,
        type: 'adult',
      );
      _successMessage = 'Persona registrada con éxito';
      await fetchPeople();
      return true;
    } catch (e) {
      _errorMessage = 'Error al registrar: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Selects a person for editing
  void startEditing(PersonModel person) {
    _editingPerson = person;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Cancels edit mode
  void cancelEditing() {
    _editingPerson = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Updates an existing person
  Future<bool> updatePerson({
    required String name,
    required String phone,
    required String birthDay,
    required bool isNew,
  }) async {
    if (_editingPerson == null) return false;

    final validationError = _validateInputs(name, phone, birthDay);
    if (validationError != null) {
      _errorMessage = validationError;
      _successMessage = null;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.updatePerson(
        id: _editingPerson!.id,
        name: name,
        phone: phone,
        birthDay: birthDay,
        isNew: isNew,
      );
      _successMessage = 'Persona actualizada con éxito';
      _editingPerson = null;
      await fetchPeople();
      return true;
    } catch (e) {
      _errorMessage = 'Error al actualizar: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Deletes a person by document ID
  Future<bool> deletePerson(String id) async {
    _deletingId = id;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.deletePerson(id);
      _successMessage = 'Persona eliminada con éxito';
      await fetchPeople();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar persona: $e';
      return false;
    } finally {
      _deletingId = null;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  String? _validateInputs(String name, String phone, String birthDay) {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        birthDay.trim().isEmpty) {
      return 'Por favor, ingresa todos los campos';
    }

    final phoneRegex = RegExp(r'^[0-9]{8}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return 'Por favor, ingresa un número de teléfono válido (8 dígitos)';
    }

    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(birthDay.trim())) {
      return 'Por favor, ingresa una fecha válida en formato dd/mm/aaaa';
    }

    return null;
  }

  static String _removeDiacritics(String str) {
    const withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const listDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeccDIIIIiiiiUUUUuuuuNnSsYyyZz';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], listDia[i]);
    }
    return result;
  }
}
