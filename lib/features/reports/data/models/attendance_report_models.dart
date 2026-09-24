import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecordModel {
  final String id;
  final String personId;
  final DateTime? date;
  final String dateString;
  final String session;
  final bool attended;

  const AttendanceRecordModel({
    required this.id,
    required this.personId,
    required this.date,
    required this.dateString,
    required this.session,
    required this.attended,
  });

  factory AttendanceRecordModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    DateTime? parsedDate;
    String dString = '';
    final rawDate = data['date'];

    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
      dString =
          '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } else if (rawDate is String) {
      dString = rawDate.trim();
      final parts = dString.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          parsedDate = DateTime(year, month, day);
        }
      } else {
        parsedDate = DateTime.tryParse(dString);
      }
    }

    return AttendanceRecordModel(
      id: id,
      personId: data['personId'] as String? ?? '',
      date: parsedDate,
      dateString: dString,
      session: (data['session'] as String? ?? 'AM').toUpperCase(),
      attended: data['attended'] as bool? ?? false,
    );
  }
}

class AttendanceReportSummary {
  final String? personId;
  final String? personName;
  final String filterDay; // 'domingo' | 'miercoles'
  final int attendedCount;
  final int totalPossibleCount;
  final double percentage;
  final List<AttendanceRecordModel> filteredRecords;

  const AttendanceReportSummary({
    this.personId,
    this.personName,
    required this.filterDay,
    required this.attendedCount,
    required this.totalPossibleCount,
    required this.percentage,
    required this.filteredRecords,
  });
}
