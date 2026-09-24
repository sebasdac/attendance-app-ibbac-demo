import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kid_model.dart';
import '../models/kids_class_model.dart';
import '../models/monthly_attendance_models.dart';

class MonthlyAttendanceRepository {
  final FirebaseFirestore _firestore;

  MonthlyAttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const List<String> monthsList = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  /// Fetch classes list from Firestore
  Future<List<KidsClass>> fetchClasses() async {
    try {
      final snapshot = await _firestore.collection('classes').get();
      return snapshot.docs
          .map((doc) => KidsClass.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get month index 1..12 from Spanish month name
  int getMonthIndex(String monthName) {
    final idx = monthsList.indexWhere(
      (m) => m.toLowerCase() == monthName.toLowerCase(),
    );
    return idx != -1 ? idx + 1 : DateTime.now().month;
  }

  /// Calculate all Sunday dates for a given year and month
  List<DateTime> getSundaysForMonth(int year, int monthIndex) {
    final List<DateTime> sundays = [];
    final daysInMonth = DateTime(year, monthIndex + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, monthIndex, day);
      if (date.weekday == DateTime.sunday) {
        sundays.add(date);
      }
    }
    return sundays;
  }

  String formatDateStr(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Generate complete monthly report for specified class, month, and year
  Future<MonthlyReportData> generateMonthlyReport({
    required String classRoom,
    required String monthName,
    required int year,
  }) async {
    final monthIndex = getMonthIndex(monthName);
    final sundayDates = getSundaysForMonth(year, monthIndex);
    final sundayStrSet = sundayDates.map(formatDateStr).toSet();

    // 1. Fetch kids enrolled in this class
    final kidsSnapshot = await _firestore.collection('kids').get();
    final allKids = kidsSnapshot.docs
        .map((doc) => KidModel.fromFirestore(doc.id, doc.data()))
        .where((k) => k.classes.contains(classRoom))
        .toList();

    final Map<String, String> kidNames = {
      for (final k in allKids) k.id: k.name,
    };

    // 2. Query attendance collection for class
    final attendanceSnapshot = await _firestore
        .collection('attendance')
        .where('class', isEqualTo: classRoom)
        .get();

    // Map dateStr => session (AM/PM) => List of kid names attended
    final Map<String, Map<String, List<String>>> sundaySessionMap = {};
    // Map kidId => Set of sunday dates attended
    final Map<String, Set<String>> kidAttendedSundays = {
      for (final k in allKids) k.id: <String>{},
    };
    // Map kidId => Map<String, bool> sundayRecords
    final Map<String, Map<String, bool>> kidSundayRecords = {
      for (final k in allKids) k.id: {for (final s in sundayStrSet) s: false},
    };

    for (final doc in attendanceSnapshot.docs) {
      final data = doc.data();
      final dateStr = data['date'] as String? ?? '';
      final session = data['session'] as String? ?? '';
      final kidId = data['kidId'] as String? ?? '';
      final attended = data['attended'] as bool? ?? false;

      if (sundayStrSet.contains(dateStr)) {
        if (!sundaySessionMap.containsKey(dateStr)) {
          sundaySessionMap[dateStr] = {'AM': [], 'PM': []};
        }

        final kidName = kidNames[kidId] ?? 'Desconocido';

        if (attended) {
          sundaySessionMap[dateStr]![session]?.add(kidName);
          kidAttendedSundays[kidId]?.add(dateStr);
          if (kidSundayRecords.containsKey(kidId)) {
            kidSundayRecords[kidId]![dateStr] = true;
          }
        }
      }
    }

    // 3. Build Weekly Stats
    final List<SundayStat> weeklyStats = [];
    int grandTotalAttendance = 0;

    for (final sunday in sundayDates) {
      final sStr = formatDateStr(sunday);
      final amAttendees = sundaySessionMap[sStr]?['AM'] ?? [];
      final pmAttendees = sundaySessionMap[sStr]?['PM'] ?? [];
      final amCount = amAttendees.length;
      final pmCount = pmAttendees.length;
      final totalCount = amCount + pmCount;

      grandTotalAttendance += totalCount;

      weeklyStats.add(
        SundayStat(
          date: sunday,
          dateStr: sStr,
          amCount: amCount,
          pmCount: pmCount,
          totalCount: totalCount,
          amAttendees: amAttendees,
          pmAttendees: pmAttendees,
        ),
      );
    }

    final totalSundays = sundayDates.length;
    final averagePerSunday = totalSundays > 0
        ? grandTotalAttendance / totalSundays
        : 0.0;

    // 4. Build Kid Details & Top Attendees
    final Map<String, KidMonthlyDetail> attendanceByKid = {};
    final List<KidAttendeeStat> topList = [];

    for (final kid in allKids) {
      final attendedCount = kidAttendedSundays[kid.id]?.length ?? 0;
      final percentage = totalSundays > 0
          ? (attendedCount / totalSundays) * 100
          : 0.0;
      final sundayRecords = kidSundayRecords[kid.id] ?? {};

      attendanceByKid[kid.name] = KidMonthlyDetail(
        kidName: kid.name,
        attendedSundays: attendedCount,
        totalSundays: totalSundays,
        percentage: percentage,
        sundayRecords: sundayRecords,
      );

      topList.add(
        KidAttendeeStat(
          kidName: kid.name,
          attendedSundays: attendedCount,
          totalSundays: totalSundays,
          percentage: percentage,
        ),
      );
    }

    topList.sort((a, b) => b.attendedSundays.compareTo(a.attendedSundays));
    final topAttendees = topList.take(5).toList();

    return MonthlyReportData(
      selectedClass: classRoom,
      selectedMonth: monthName,
      year: year,
      totalSundays: totalSundays,
      totalAttendance: grandTotalAttendance,
      averagePerSunday: averagePerSunday,
      weeklyStats: weeklyStats,
      topAttendees: topAttendees,
      attendanceByKid: attendanceByKid,
    );
  }
}
