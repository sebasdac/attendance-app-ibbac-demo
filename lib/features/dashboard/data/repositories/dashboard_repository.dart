import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore;

  static const List<String> monthNames = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sept',
    'oct',
    'nov',
    'dic',
  ];

  DashboardRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch top 3 attendees excluding people listed in `excludedPeople` collection.
  Future<List<TopAttendee>> fetchTop3Attendees() async {
    try {
      final countsSnapshot = await _firestore
          .collection('attendanceCounts')
          .get();

      final allData = countsSnapshot.docs
          .map((doc) => TopAttendee.fromFirestore(doc.data()))
          .toList();

      final excludedSnapshot = await _firestore
          .collection('excludedPeople')
          .get();

      final excludedNames = excludedSnapshot.docs
          .map((doc) => (doc.data()['name'] as String? ?? '').trim())
          .toSet();

      final top3 =
          allData
              .where((person) => !excludedNames.contains(person.name.trim()))
              .toList()
            ..sort((a, b) => b.count.compareTo(a.count));

      return top3.take(3).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch last session info and count people who attended.
  Future<LastSessionInfo?> fetchLastSession() async {
    try {
      final attendanceRef = _firestore.collection('attendance');

      final lastQuery = await attendanceRef
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (lastQuery.docs.isEmpty) return null;

      final lastData = lastQuery.docs.first.data();
      final lastDate = lastData['date'] as String?;
      final lastSession = lastData['session'] as String?;

      if (lastDate == null || lastSession == null) return null;

      final sessionQuery = await attendanceRef
          .where('date', isEqualTo: lastDate)
          .where('session', isEqualTo: lastSession)
          .get();

      int attendedCount = 0;
      for (final doc in sessionQuery.docs) {
        final data = doc.data();
        if (data['attended'] == true) {
          attendedCount++;
        }
      }

      return LastSessionInfo(
        attended: attendedCount,
        session: lastSession,
        date: lastDate,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch monthly attendance summary for the current year.
  Future<List<MonthlyAttendance>> fetchMonthlyAttendance() async {
    try {
      final year = DateTime.now().year.toString();
      final summaryDoc = await _firestore
          .collection('attendanceSummary')
          .doc(year)
          .get();

      if (!summaryDoc.exists || summaryDoc.data() == null) {
        return monthNames
            .map((m) => MonthlyAttendance(month: m, count: 0))
            .toList();
      }

      final data = summaryDoc.data()!;
      return monthNames.map((month) {
        final val = data[month] ?? (month == 'sept' ? data['sep'] : null);
        final count = (val as num?)?.toInt() ?? 0;
        return MonthlyAttendance(month: month, count: count);
      }).toList();
    } catch (e) {
      return monthNames
          .map((m) => MonthlyAttendance(month: m, count: 0))
          .toList();
    }
  }

  static const List<String> fullMonthNames = [
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

  /// Fetch birthday data for current month from `people` and `kids` collections.
  Future<BirthdayReportData> fetchCurrentMonthBirthdays() async {
    final now = DateTime.now();
    final currentMonth = now.month;
    final monthName = fullMonthNames[currentMonth - 1];

    final peopleSnapshot = await _firestore.collection('people').get();
    final kidsSnapshot = await _firestore.collection('kids').get();

    final List<BirthdayPerson> allBirthdays = [];

    for (final doc in peopleSnapshot.docs) {
      final person = BirthdayPerson.fromFirestore(doc.id, doc.data(), 'Adulto');
      if (person.month == currentMonth) {
        allBirthdays.add(person);
      }
    }

    for (final doc in kidsSnapshot.docs) {
      final person = BirthdayPerson.fromFirestore(doc.id, doc.data(), 'Niño');
      if (person.month == currentMonth) {
        allBirthdays.add(person);
      }
    }

    allBirthdays.sort((a, b) {
      final dayA = a.day ?? 0;
      final dayB = b.day ?? 0;
      if (dayA != dayB) {
        return dayA.compareTo(dayB);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return BirthdayReportData(
      currentMonth: currentMonth,
      monthName: monthName,
      birthdays: allBirthdays,
    );
  }
}
