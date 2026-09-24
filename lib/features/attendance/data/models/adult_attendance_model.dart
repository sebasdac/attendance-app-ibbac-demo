class AdultAttendanceRecord {
  final String? id;
  final String personId;
  final String date;
  final String session;
  final bool attended;

  AdultAttendanceRecord({
    this.id,
    required this.personId,
    required this.date,
    required this.session,
    required this.attended,
  });

  factory AdultAttendanceRecord.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return AdultAttendanceRecord(
      id: documentId,
      personId: data['personId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      session: data['session'] as String? ?? '',
      attended: data['attended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personId': personId,
      'date': date,
      'session': session,
      'attended': attended,
    };
  }
}
