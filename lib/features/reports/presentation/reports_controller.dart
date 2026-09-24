import 'package:flutter/foundation.dart';
import '../../../core/utils/daily_pdf_generator.dart';
import '../../people/data/models/person_model.dart';
import '../data/models/attendance_report_models.dart';
import '../data/repositories/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  final ReportsRepository _repository;

  ReportsController({ReportsRepository? repository})
    : _repository = repository ?? ReportsRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- Daily Analytics State ---
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  DailyReportData? _dailyData;
  DailyReportData? get dailyData => _dailyData;

  List<PersonModel> _people = [];
  List<PersonModel> get people => _people;

  List<PersonModel> _filteredPeople = [];
  List<PersonModel> get filteredPeople => _filteredPeople;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _dataLoaded = false;
  bool get dataLoaded => _dataLoaded;

  bool _loadingPeople = false;
  bool get loadingPeople => _loadingPeople;

  bool _generatingPdf = false;
  bool get generatingPdf => _generatingPdf;

  // --- Individual Report State ---
  PersonModel? _selectedPersonForReport;
  PersonModel? get selectedPersonForReport => _selectedPersonForReport;

  List<AttendanceRecordModel> _rawIndividualRecords = [];
  String _filterDay = 'domingo'; // 'domingo' | 'miercoles'
  String get filterDay => _filterDay;

  int _visibleCount = 6;
  int get visibleCount => _visibleCount;

  DateTime? _initialDate;
  DateTime? get initialDate => _initialDate;

  int _totalPossibleCount = 0;
  int get totalPossibleCount => _totalPossibleCount;

  int _attendedCount = 0;
  int get attendedCount => _attendedCount;

  double _percentage = 0.0;
  double get percentage => _percentage;

  List<AttendanceRecordModel> _filteredIndividualRecords = [];
  List<AttendanceRecordModel> get filteredIndividualRecords =>
      _filteredIndividualRecords;

  List<AttendanceRecordModel> get visibleIndividualRecords =>
      _filteredIndividualRecords.take(_visibleCount).toList();

  bool get hasMoreIndividualRecords =>
      _visibleCount < _filteredIndividualRecords.length;

  Future<void> init({String? initialPersonId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load initial date setting for individual reports
      final initialDateStr = await _repository.fetchInitialDate();
      _initialDate = _parseDateString(initialDateStr) ?? DateTime(2024, 1, 1);

      // Load daily attendance data for today
      await fetchDailyAttendance(_selectedDate);

      // If initialPersonId was passed via route, select that person for individual view
      if (initialPersonId != null && initialPersonId.isNotEmpty) {
        _people = await _repository.fetchPeople();
        final found = _people.where((p) => p.id == initialPersonId).firstOrNull;
        if (found != null) {
          await selectPersonForReport(found);
        }
      }
    } catch (e) {
      _errorMessage = 'Error al cargar las estadísticas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDailyAttendance(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    try {
      _dailyData = await _repository.fetchDailyAttendance(date);
    } catch (e) {
      _errorMessage = 'Error al obtener datos de asistencia: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPeople() async {
    _loadingPeople = true;
    notifyListeners();

    try {
      _people = await _repository.fetchPeople();
      _filteredPeople = List.from(_people);
      _dataLoaded = true;
    } catch (e) {
      _errorMessage = 'Error al cargar lista de personas: $e';
    } finally {
      _loadingPeople = false;
      notifyListeners();
    }
  }

  void filterPeople(String text) {
    _searchQuery = text;
    final normalized = _normalizeText(text);
    _filteredPeople = _people
        .where((p) => _normalizeText(p.name).contains(normalized))
        .toList();
    notifyListeners();
  }

  Future<void> generateDailyPdf() async {
    if (_generatingPdf || _dailyData == null) return;
    _generatingPdf = true;
    notifyListeners();

    try {
      await DailyPdfGenerator.generateAndSharePdf(_dailyData!);
    } catch (e) {
      _errorMessage = 'No se pudo generar el reporte PDF: $e';
    } finally {
      _generatingPdf = false;
      notifyListeners();
    }
  }

  Future<void> selectPersonForReport(PersonModel person) async {
    _selectedPersonForReport = person;
    _visibleCount = 6;
    _isLoading = true;
    notifyListeners();

    try {
      _rawIndividualRecords = await _repository.fetchAttendanceForPerson(
        person.id,
      );
      _calculateIndividualMetrics();
    } catch (e) {
      _errorMessage = 'Error al consultar la asistencia de la persona: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedPerson() {
    _selectedPersonForReport = null;
    notifyListeners();
  }

  void setFilterDay(String day) {
    if (_filterDay == day) return;
    _filterDay = day;
    _visibleCount = 6;
    _calculateIndividualMetrics();
    notifyListeners();
  }

  void loadMoreIndividualRecords() {
    _visibleCount += 6;
    notifyListeners();
  }

  void _calculateIndividualMetrics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = _initialDate ?? DateTime(2024, 1, 1);

    if (_filterDay == 'domingo') {
      int sundays = 0;
      DateTime current = startDate;
      while (!current.isAfter(today)) {
        if (current.weekday == DateTime.sunday) {
          sundays++;
        }
        current = current.add(const Duration(days: 1));
      }
      _totalPossibleCount = sundays * 2;

      _filteredIndividualRecords = _rawIndividualRecords.where((r) {
        if (!r.attended) return false;
        if (r.date != null) {
          return r.date!.weekday == DateTime.sunday;
        }
        return true;
      }).toList();
    } else {
      int wednesdays = 0;
      DateTime current = startDate;
      while (!current.isAfter(today)) {
        if (current.weekday == DateTime.wednesday) {
          wednesdays++;
        }
        current = current.add(const Duration(days: 1));
      }
      _totalPossibleCount = wednesdays * 1;

      _filteredIndividualRecords = _rawIndividualRecords.where((r) {
        if (!r.attended) return false;
        if (r.date != null) {
          return r.date!.weekday == DateTime.wednesday;
        }
        return true;
      }).toList();
    }

    _filteredIndividualRecords.sort((a, b) {
      final dateA = a.date ?? DateTime(1970);
      final dateB = b.date ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    _attendedCount = _filteredIndividualRecords.length;

    if (_totalPossibleCount > 0) {
      _percentage = ((_attendedCount / _totalPossibleCount) * 100).clamp(
        0.0,
        100.0,
      );
    } else {
      _percentage = 0.0;
    }
  }

  String _normalizeText(String text) {
    final withAccents = 'áéíóúÁÉÍÓÚñÑ';
    final withoutAccents = 'aeiouAEIOUnN';
    String result = text;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result.toLowerCase();
  }

  DateTime? _parseDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(dateStr);
  }
}
