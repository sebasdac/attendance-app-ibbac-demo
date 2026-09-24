import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../people/data/models/person_model.dart';
import '../models/adult_attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;

  AttendanceRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const List<String> _spanishMonths = [
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

  String _getMonthKey(DateTime date) => _spanishMonths[date.month - 1];

  /// Fetch all registered adults sorted alphabetically
  Future<List<PersonModel>> fetchPeople() async {
    final snapshot = await _firestore.collection('people').get();
    final people = snapshot.docs
        .map((doc) => PersonModel.fromFirestore(doc.data(), doc.id))
        .toList();

    people.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return people;
  }

  /// Fetch existing attendance records for a specific date (YYYY-MM-DD) and session (AM/PM)
  Future<Map<String, AdultAttendanceRecord>> fetchSessionAttendance(
    String date,
    String session,
  ) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('date', isEqualTo: date)
        .where('session', isEqualTo: session)
        .get();

    final Map<String, AdultAttendanceRecord> map = {};
    for (final doc in snapshot.docs) {
      final record = AdultAttendanceRecord.fromFirestore(doc.data(), doc.id);
      if (record.personId.isNotEmpty) {
        map[record.personId] = record;
      }
    }
    return map;
  }

  /// Save attendance state in batch to Firestore
  Future<void> saveAttendanceBatch({
    required String dateStr,
    required String session,
    required Map<String, bool> attendanceState,
    required Map<String, AdultAttendanceRecord> initialRecords,
    required Map<String, String> personNames,
  }) async {
    final DateTime dateObj = DateTime.parse(dateStr);
    final String year = dateObj.year.toString();
    final String monthKey = _getMonthKey(dateObj);

    int netMonthlyDelta = 0;
    final Map<String, int> personDeltas = {};

    final batch = _firestore.batch();
    final attendanceCollection = _firestore.collection('attendance');

    for (final entry in attendanceState.entries) {
      final String personId = entry.key;
      final bool isAttended = entry.value;

      final AdultAttendanceRecord? existing = initialRecords[personId];

      if (existing == null) {
        // 1. Create new record
        final newDocRef = attendanceCollection.doc();
        batch.set(
          newDocRef,
          AdultAttendanceRecord(
            personId: personId,
            date: dateStr,
            session: session,
            attended: isAttended,
          ).toFirestore(),
        );

        if (isAttended) {
          netMonthlyDelta += 1;
          personDeltas[personId] = 1;
        }
      } else {
        // 2. Update existing if state changed
        final bool prevAttended = existing.attended;
        if (prevAttended != isAttended && existing.id != null) {
          final docRef = attendanceCollection.doc(existing.id);
          batch.update(docRef, {'attended': isAttended});

          if (!prevAttended && isAttended) {
            netMonthlyDelta += 1;
            personDeltas[personId] = 1;
          } else if (prevAttended && !isAttended) {
            netMonthlyDelta -= 1;
            personDeltas[personId] = -1;
          }
        }
      }
    }

    // Commit batch for attendance collection
    await batch.commit();

    // 3. Update Monthly Summary if net delta changed
    if (netMonthlyDelta != 0) {
      await _updateMonthlySummary(year, monthKey, netMonthlyDelta);
    }

    // 4. Update Person Attendance Counts for affected people
    for (final entry in personDeltas.entries) {
      final personId = entry.key;
      final delta = entry.value;
      final name = personNames[personId] ?? 'Desconocido';
      await _updatePersonAttendanceCount(personId, name, delta);
    }
  }

  Future<void> _updateMonthlySummary(
    String year,
    String monthKey,
    int delta,
  ) async {
    try {
      final summaryRef = _firestore.collection('attendanceSummary').doc(year);
      final summarySnap = await summaryRef.get();

      if (summarySnap.exists) {
        final data = summarySnap.data() ?? {};
        final int currentCount = (data[monthKey] as num?)?.toInt() ?? 0;
        final int newCount = (currentCount + delta).clamp(0, 999999);
        await summaryRef.update({monthKey: newCount});
      } else if (delta > 0) {
        await summaryRef.set({monthKey: delta});
      }
    } catch (e) {
      // Non-blocking log
    }
  }

  Future<void> _updatePersonAttendanceCount(
    String personId,
    String personName,
    int delta,
  ) async {
    try {
      final countRef = _firestore.collection('attendanceCounts').doc(personId);
      final countSnap = await countRef.get();

      if (countSnap.exists) {
        final data = countSnap.data() ?? {};
        final int currentCount = (data['count'] as num?)?.toInt() ?? 0;
        final int newCount = (currentCount + delta).clamp(0, 999999);
        await countRef.update({'count': newCount, 'name': personName});
      } else if (delta > 0) {
        await countRef.set({'count': delta, 'name': personName});
      }
    } catch (e) {
      // Non-blocking log
    }
  }
}
