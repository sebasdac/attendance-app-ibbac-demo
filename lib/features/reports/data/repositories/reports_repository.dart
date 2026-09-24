import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/daily_pdf_generator.dart';
import '../../../people/data/models/person_model.dart';
import '../models/attendance_report_models.dart';

class ReportsRepository {
  final FirebaseFirestore _firestore;

  ReportsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches global initialDate setting from Firestore doc `config/globalSettings`
  Future<String?> fetchInitialDate() async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('globalSettings')
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()?['initialDate'] as String?;
      }
    } catch (e) {
      // Return null on error so controller can use fallback
    }
    return null;
  }

  /// Fetches daily attendance metrics for a specific date
  Future<DailyReportData> fetchDailyAttendance(DateTime date) async {
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    int amKids = 0;
    int amAdults = 0;
    int pmKids = 0;
    int pmAdults = 0;

    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: dateString)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final attended = data['attended'] as bool? ?? false;
        if (attended) {
          final session = (data['session'] as String? ?? 'AM').toUpperCase();
          final isKid = data['kidId'] != null && data['class'] != null;
          final isAdult = data['kidId'] == null && data['class'] == null;

          if (session == 'AM') {
            if (isKid) amKids++;
            if (isAdult) amAdults++;
          } else if (session == 'PM') {
            if (isKid) pmKids++;
            if (isAdult) pmAdults++;
          }
        }
      }
    } catch (e) {
      // Handle error gracefully
    }

    return DailyReportData(
      date: date,
      amKids: amKids,
      amAdults: amAdults,
      pmKids: pmKids,
      pmAdults: pmAdults,
    );
  }

  /// Fetches attendance records for a given person ID (including linked kids class attendance)
  Future<List<AttendanceRecordModel>> fetchAttendanceForPerson(
    String personId,
  ) async {
    try {
      final List<AttendanceRecordModel> allRecords = [];

      // 1. Fetch records with personId
      final snapshot = await _firestore
          .collection('attendance')
          .where('personId', isEqualTo: personId)
          .get();

      allRecords.addAll(
        snapshot.docs.map(
          (doc) => AttendanceRecordModel.fromFirestore(doc.data(), doc.id),
        ),
      );

      // 2. Check if this person has a linkedKidId in people collection
      String? linkedKidId;
      try {
        final personDoc =
            await _firestore.collection('people').doc(personId).get();
        if (personDoc.exists && personDoc.data() != null) {
          linkedKidId = personDoc.data()?['linkedKidId'] as String?;
        }
      } catch (_) {}

      // 3. Fetch kid attendance records if linked, or check if personId matches kidId
      final targetKidId = linkedKidId ?? personId;
      final kidSnapshot = await _firestore
          .collection('attendance')
          .where('kidId', isEqualTo: targetKidId)
          .get();

      for (final doc in kidSnapshot.docs) {
        allRecords.add(
          AttendanceRecordModel.fromFirestore(doc.data(), doc.id),
        );
      }

      // Deduplicate by attendance document ID
      final Map<String, AttendanceRecordModel> uniqueMap = {};
      for (final r in allRecords) {
        uniqueMap[r.id] = r;
      }

      return uniqueMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetches all people sorted by name
  Future<List<PersonModel>> fetchPeople() async {
    try {
      final snapshot = await _firestore.collection('people').get();
      final people = snapshot.docs
          .map((doc) => PersonModel.fromFirestore(doc.data(), doc.id))
          .toList();

      people.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return people;
    } catch (e) {
      return [];
    }
  }
}
