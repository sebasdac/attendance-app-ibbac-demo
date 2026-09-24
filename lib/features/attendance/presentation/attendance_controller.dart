import 'package:flutter/foundation.dart';
import '../../people/data/models/person_model.dart';
import '../data/models/adult_attendance_model.dart';
import '../data/repositories/attendance_repository.dart';

class AttendanceController extends ChangeNotifier {
  final AttendanceRepository _repository;

  AttendanceController({AttendanceRepository? repository})
    : _repository = repository ?? AttendanceRepository();

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  String? _selectedSession; // 'AM' or 'PM'
  String? get selectedSession => _selectedSession;

  bool _isTakingAttendance = false;
  bool get isTakingAttendance => _isTakingAttendance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<PersonModel> _people = [];
  List<PersonModel> get people => _people;

  List<PersonModel> _filteredPeople = [];
  List<PersonModel> get filteredPeople => _filteredPeople;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _statusFilter = 'all'; // 'all', 'present', 'absent'
  String get statusFilter => _statusFilter;

  // personId -> attended (bool)
  final Map<String, bool> _attendanceState = {};
  Map<String, bool> get attendanceState => _attendanceState;

  // personId -> initial AdultAttendanceRecord
  Map<String, AdultAttendanceRecord> _initialRecords = {};

  int get attendedCount =>
      _people.where((p) => _attendanceState[p.id] == true).length;
  int get totalCount => _people.length;
  int get absentCount => totalCount - attendedCount;
  int get attendancePercentage =>
      totalCount > 0 ? ((attendedCount / totalCount) * 100).round() : 0;

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedSession(String session) {
    _selectedSession = session;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void backToSelection() {
    _isTakingAttendance = false;
    notifyListeners();
  }

  Future<void> startTakingAttendance() async {
    if (_selectedSession == null) {
      _errorMessage = 'Por favor selecciona una sesión (Mañana o Tarde).';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final peopleList = await _repository.fetchPeople();
      final recordsMap = await _repository.fetchSessionAttendance(
        dateStr,
        _selectedSession!,
      );

      _people = peopleList;
      _initialRecords = recordsMap;
      _attendanceState.clear();

      for (final p in peopleList) {
        _attendanceState[p.id] = recordsMap[p.id]?.attended ?? false;
      }

      _applyFilter();
      _isTakingAttendance = true;
    } catch (e) {
      _errorMessage = 'Error al cargar la asistencia: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleAttendance(String personId, bool attended) {
    _attendanceState[personId] = attended;
    _applyFilter();
    notifyListeners();
  }

  void markAllFiltered(bool attended) {
    for (final p in _filteredPeople) {
      _attendanceState[p.id] = attended;
    }
    _applyFilter();
    notifyListeners();
  }

  void setSearchQuery(String text) {
    _searchQuery = text;
    _applyFilter();
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    List<PersonModel> result = List.from(_people);

    if (_searchQuery.trim().isNotEmpty) {
      final queryNorm = _normalizeText(_searchQuery);
      result = result
          .where((p) => _normalizeText(p.name).contains(queryNorm))
          .toList();
    }

    if (_statusFilter == 'present') {
      result = result.where((p) => _attendanceState[p.id] == true).toList();
    } else if (_statusFilter == 'absent') {
      result = result.where((p) => _attendanceState[p.id] != true).toList();
    }

    _filteredPeople = result;
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n');
  }

  Future<bool> saveAttendance() async {
    if (_selectedSession == null) return false;

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final Map<String, String> personNames = {};
      for (final p in _people) {
        personNames[p.id] = p.name;
      }

      await _repository.saveAttendanceBatch(
        dateStr: dateStr,
        session: _selectedSession!,
        attendanceState: _attendanceState,
        initialRecords: _initialRecords,
        personNames: personNames,
      );

      _successMessage = '¡Asistencia guardada correctamente!';

      // Refresh initial records after saving
      final updatedRecords = await _repository.fetchSessionAttendance(
        dateStr,
        _selectedSession!,
      );
      _initialRecords = updatedRecords;

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar asistencia: ${e.toString()}';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
