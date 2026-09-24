import 'package:flutter/foundation.dart';
import '../data/models/kids_class_model.dart';
import '../data/models/monthly_attendance_models.dart';
import '../data/repositories/monthly_attendance_repository.dart';

class MonthlyAttendanceController extends ChangeNotifier {
  final MonthlyAttendanceRepository _repository;

  List<KidsClass> _classes = [];
  String _selectedClass = '';
  String _selectedMonth = '';
  int _selectedYear = DateTime.now().year;

  String _reportType = 'overview'; // 'overview' | 'detailed'
  String _detailedView = 'calendar'; // 'calendar' | 'individual'

  bool _isLoading = false;
  String? _errorMessage;
  MonthlyReportData? _monthlyReport;

  MonthlyAttendanceController({MonthlyAttendanceRepository? repository})
    : _repository = repository ?? MonthlyAttendanceRepository() {
    _selectedMonth =
        MonthlyAttendanceRepository.monthsList[DateTime.now().month - 1];
    loadClasses();
  }

  // Getters
  List<KidsClass> get classes => _classes;
  String get selectedClass => _selectedClass;
  String get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  String get reportType => _reportType;
  String get detailedView => _detailedView;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MonthlyReportData? get monthlyReport => _monthlyReport;
  List<String> get monthsList => MonthlyAttendanceRepository.monthsList;

  void setSelectedClass(String className) {
    _selectedClass = className;
    notifyListeners();
    generateReport();
  }

  void setSelectedMonth(String month) {
    _selectedMonth = month;
    notifyListeners();
    generateReport();
  }

  void setSelectedYear(int year) {
    _selectedYear = year;
    notifyListeners();
    generateReport();
  }

  void setReportType(String type) {
    _reportType = type;
    notifyListeners();
  }

  void setDetailedView(String view) {
    _detailedView = view;
    notifyListeners();
  }

  /// Load available classes list from Firestore
  Future<void> loadClasses() async {
    try {
      _classes = await _repository.fetchClasses();
      if (_classes.isNotEmpty && _selectedClass.isEmpty) {
        _selectedClass = _classes.first.name;
      }
      notifyListeners();
      if (_selectedClass.isNotEmpty) {
        generateReport();
      }
    } catch (_) {}
  }

  /// Generate monthly report for selected class and month
  Future<void> generateReport() async {
    if (_selectedClass.isEmpty || _selectedMonth.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _monthlyReport = await _repository.generateMonthlyReport(
        classRoom: _selectedClass,
        monthName: _selectedMonth,
        year: _selectedYear,
      );
    } catch (e) {
      _errorMessage = 'Error al generar reporte mensual: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
