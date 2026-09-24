class KidsAttendanceRecord {
  final String? id;
  final String kidId;
  final String date;
  final String session;
  final String classRoom;
  final bool attended;

  KidsAttendanceRecord({
    this.id,
    required this.kidId,
    required this.date,
    required this.session,
    required this.classRoom,
    required this.attended,
  });

  factory KidsAttendanceRecord.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return KidsAttendanceRecord(
      id: id,
      kidId: data['kidId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      session: data['session'] as String? ?? '',
      classRoom: data['class'] as String? ?? '',
      attended: data['attended'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'kidId': kidId,
      'date': date,
      'session': session,
      'class': classRoom,
      'attended': attended,
    };
  }
}
