import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/kid_model.dart';
import '../models/kids_attendance_model.dart';
import '../models/kids_class_model.dart';

class KidsRepository {
  final FirebaseFirestore _firestore;

  KidsRepository({FirebaseFirestore? firestore})
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

  /// Fetch all registered classes from `classes` Firestore collection
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

  /// Add a new class to `classes` Firestore collection
  Future<bool> addClass(String className) async {
    try {
      await _firestore.collection('classes').add({
        'name': className,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a class by document ID from `classes` Firestore collection
  Future<bool> deleteClass(String classId) async {
    try {
      await _firestore.collection('classes').doc(classId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all kids from `kids` Firestore collection
  Future<List<KidModel>> fetchKids() async {
    try {
      final snapshot = await _firestore.collection('kids').get();
      return snapshot.docs
          .map((doc) => KidModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch kids enrolled in a specific class
  Future<List<KidModel>> fetchKidsByClass(String classRoom) async {
    try {
      final allKids = await fetchKids();
      return allKids.where((k) => k.classes.contains(classRoom)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch existing kids attendance records for a specific date (YYYY-MM-DD), session (AM/PM), and class
  Future<Map<String, KidsAttendanceRecord>> fetchKidsAttendance({
    required String date,
    required String session,
    required String classRoom,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: date)
          .where('session', isEqualTo: session)
          .where('class', isEqualTo: classRoom)
          .get();

      final Map<String, KidsAttendanceRecord> result = {};
      for (final doc in snapshot.docs) {
        final record = KidsAttendanceRecord.fromFirestore(doc.data(), doc.id);
        if (record.kidId.isNotEmpty) {
          result[record.kidId] = record;
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Save attendance state for kids in batch to Firestore
  Future<void> saveKidsAttendanceBatch({
    required String dateStr,
    required String session,
    required String classRoom,
    required Map<String, bool> attendanceState,
    required Map<String, KidsAttendanceRecord> initialRecords,
  }) async {
    final DateTime dateObj = DateTime.parse(dateStr);
    final String year = dateObj.year.toString();
    final String monthKey = _getMonthKey(dateObj);

    int netMonthlyDelta = 0;
    final batch = _firestore.batch();
    final attendanceCollection = _firestore.collection('attendance');

    for (final entry in attendanceState.entries) {
      final String kidId = entry.key;
      final bool isAttended = entry.value;
      final KidsAttendanceRecord? existing = initialRecords[kidId];

      if (existing == null) {
        // 1. Create new attendance doc
        final newDocRef = attendanceCollection.doc();
        batch.set(
          newDocRef,
          KidsAttendanceRecord(
            kidId: kidId,
            date: dateStr,
            session: session,
            classRoom: classRoom,
            attended: isAttended,
          ).toFirestore(),
        );

        if (isAttended) {
          netMonthlyDelta += 1;
        }
      } else {
        // 2. Update existing doc if state changed
        final bool prevAttended = existing.attended;
        if (prevAttended != isAttended && existing.id != null) {
          final docRef = attendanceCollection.doc(existing.id);
          batch.update(docRef, {'attended': isAttended});

          if (!prevAttended && isAttended) {
            netMonthlyDelta += 1;
          } else if (prevAttended && !isAttended) {
            netMonthlyDelta -= 1;
          }
        }
      }
    }

    // Commit batch write
    await batch.commit();

    // 3. Update Monthly Summary if net delta changed
    if (netMonthlyDelta != 0) {
      await _updateMonthlySummary(year, monthKey, netMonthlyDelta);
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
        // Check for 'sept' or 'sep' key compatibility
        String targetKey = monthKey;
        if (monthKey == 'sept' &&
            !data.containsKey('sept') &&
            data.containsKey('sep')) {
          targetKey = 'sep';
        }
        final int currentCount = (data[targetKey] as num?)?.toInt() ?? 0;
        final int newCount = (currentCount + delta).clamp(0, 999999);
        await summaryRef.update({targetKey: newCount});
      } else if (delta > 0) {
        await summaryRef.set({monthKey: delta});
      }
    } catch (e) {
      // Non-blocking catch
    }
  }

  /// Add a new kid to `kids` collection
  Future<void> addKid(KidModel kid) async {
    await _firestore.collection('kids').add(kid.toMap());
  }

  /// Update an existing kid document in `kids` collection
  Future<void> updateKid(KidModel kid) async {
    await _firestore.collection('kids').doc(kid.id).update({
      'name': kid.name,
      'birthDay': kid.birthDay,
      'classes': kid.classes,
      'isNew': kid.isNew,
      'comments': kid.comments,
    });
  }

  /// Delete a kid document from `kids` collection
  Future<void> deleteKid(String id) async {
    await _firestore.collection('kids').doc(id).delete();
  }
}
