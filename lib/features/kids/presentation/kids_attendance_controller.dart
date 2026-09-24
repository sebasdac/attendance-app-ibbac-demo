import 'package:flutter/foundation.dart';
import '../data/models/kid_model.dart';
import '../data/models/kids_attendance_model.dart';
import '../data/repositories/kids_repository.dart';

class KidsAttendanceController extends ChangeNotifier {
  final KidsRepository _repository;

  final String classRoom;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSession;
  int _step = 1; // 1: Date & Session, 2: Attendance Taking

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<KidModel> _kids = [];
  Map<String, bool> _attendanceState = {};
  Map<String, KidsAttendanceRecord> _initialRecords = {};

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _statusFilter = 'all'; // 'all', 'present', 'absent'
  String get statusFilter => _statusFilter;

  KidsAttendanceController({
    required this.classRoom,
    KidsRepository? repository,
  }) : _repository = repository ?? KidsRepository();

  // Getters
  DateTime get selectedDate => _selectedDate;
  String? get selectedSession => _selectedSession;
  int get step => _step;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearErrorMessage() {
    _errorMessage = null;
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  List<KidModel> get kids => _kids;
  Map<String, bool> get attendanceState => _attendanceState;

  List<KidModel> get filteredKids {
    List<KidModel> list = List.from(_kids);

    if (_searchQuery.trim().isNotEmpty) {
      final queryNorm = _normalizeText(_searchQuery);
      list = list
          .where((k) => _normalizeText(k.name).contains(queryNorm))
          .toList();
    }

    if (_statusFilter == 'present') {
      list = list.where((k) => _attendanceState[k.id] == true).toList();
    } else if (_statusFilter == 'absent') {
      list = list.where((k) => _attendanceState[k.id] != true).toList();
    }

    return list;
  }

  int get totalKids => _kids.length;
  int get attendedCount =>
      _attendanceState.values.where((v) => v == true).length;
  int get absentCount => totalKids - attendedCount;
  int get pendingCount => totalKids - attendedCount;

  bool get hasChanges => _attendanceState.isNotEmpty;

  /// YYYY-MM-DD date string
  String get formattedDateStr {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedSession(String session) {
    _selectedSession = session;
    notifyListeners();
  }

  void setStep(int newStep) {
    _step = newStep;
    notifyListeners();
  }

  void setAttendance(String kidId, bool attended) {
    _attendanceState[kidId] = attended;
    notifyListeners();
  }

  void setSearchQuery(String text) {
    _searchQuery = text;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  void markAllFiltered(bool attended) {
    for (final k in filteredKids) {
      _attendanceState[k.id] = attended;
    }
    notifyListeners();
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  /// Load kids belonging to classRoom and fetch any saved attendance records
  Future<void> loadKidsAndAttendance() async {
    if (_selectedSession == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch kids by class
      _kids = await _repository.fetchKidsByClass(classRoom);

      // 2. Fetch attendance doc records for specified date, session, and class
      _initialRecords = await _repository.fetchKidsAttendance(
        date: formattedDateStr,
        session: _selectedSession!,
        classRoom: classRoom,
      );

      // 3. Populate state map
      _attendanceState = {};
      for (final entry in _initialRecords.entries) {
        _attendanceState[entry.key] = entry.value.attended;
      }

      _step = 2;
    } catch (e) {
      _errorMessage = 'Error al cargar estudiantes o asistencia: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save attendance state to Firestore
  Future<bool> saveAttendance() async {
    if (_attendanceState.isEmpty || _selectedSession == null) {
      _errorMessage = 'No hay cambios en la asistencia para guardar';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.saveKidsAttendanceBatch(
        dateStr: formattedDateStr,
        session: _selectedSession!,
        classRoom: classRoom,
        attendanceState: _attendanceState,
        initialRecords: _initialRecords,
      );

      _successMessage = '¡La asistencia se guardó correctamente!';
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar la asistencia: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
