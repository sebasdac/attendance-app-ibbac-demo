import 'package:flutter/foundation.dart';
import '../../../core/utils/birthday_pdf_generator.dart';
import '../data/models/dashboard_models.dart';
import '../data/repositories/dashboard_repository.dart';

class DashboardController extends ChangeNotifier {
  final DashboardRepository _repository;

  // In-memory cache to prevent redundant Firestore queries when navigating to Home
  static List<TopAttendee>? _cachedTop3Attendees;
  static LastSessionInfo? _cachedLastSession;
  static List<MonthlyAttendance>? _cachedMonthlyAttendance;
  static bool _hasLoadedOnce = false;

  bool _isLoading = true;
  bool _isGeneratingReport = false;
  String? _errorMessage;

  List<TopAttendee> _top3Attendees = [];
  LastSessionInfo? _lastSession;
  List<MonthlyAttendance> _monthlyAttendance = [];

  DashboardController({DashboardRepository? repository})
    : _repository = repository ?? DashboardRepository() {
    loadDashboardData();
  }

  bool get isLoading => _isLoading;
  bool get isGeneratingReport => _isGeneratingReport;
  String? get errorMessage => _errorMessage;

  List<TopAttendee> get top3Attendees => _top3Attendees;
  LastSessionInfo? get lastSession => _lastSession;
  List<MonthlyAttendance> get monthlyAttendance => _monthlyAttendance;

  int get totalYearAttendance =>
      _monthlyAttendance.fold(0, (sum, item) => sum + item.count);

  int get monthlyAverage =>
      _monthlyAttendance.isEmpty ? 0 : (totalYearAttendance / 12).round();

  /// Invalidate cache manually when needed (e.g. after adding attendance)
  static void invalidateCache() {
    _cachedTop3Attendees = null;
    _cachedLastSession = null;
    _cachedMonthlyAttendance = null;
    _hasLoadedOnce = false;
  }

  /// Fetch all dashboard metrics (uses memory cache unless forceRefresh is true)
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    // If we already have cached data in memory and forceRefresh is false, serve instantly with 0 Firestore reads
    if (!forceRefresh &&
        _hasLoadedOnce &&
        _cachedTop3Attendees != null &&
        _cachedMonthlyAttendance != null) {
      _top3Attendees = _cachedTop3Attendees!;
      _lastSession = _cachedLastSession;
      _monthlyAttendance = _cachedMonthlyAttendance!;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchTop3Attendees(),
        _repository.fetchLastSession(),
        _repository.fetchMonthlyAttendance(),
      ]);

      _top3Attendees = results[0] as List<TopAttendee>;
      _lastSession = results[1] as LastSessionInfo?;
      _monthlyAttendance = results[2] as List<MonthlyAttendance>;

      // Cache data in memory
      _cachedTop3Attendees = _top3Attendees;
      _cachedLastSession = _lastSession;
      _cachedMonthlyAttendance = _monthlyAttendance;
      _hasLoadedOnce = true;
    } catch (e) {
      _errorMessage = 'Error al cargar los datos del dashboard';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Action for birthday report PDF generation
  Future<bool> generateBirthdayReport() async {
    _isGeneratingReport = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reportData = await _repository.fetchCurrentMonthBirthdays();
      await BirthdayPdfGenerator.generateAndSharePdf(reportData);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Error generando reporte PDF de cumpleaños: $e');
      debugPrint(stackTrace.toString());
      _errorMessage = 'Error al generar PDF: $e';
      return false;
    } finally {
      _isGeneratingReport = false;
      notifyListeners();
    }
  }
}
