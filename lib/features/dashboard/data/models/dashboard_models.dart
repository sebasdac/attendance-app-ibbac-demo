import 'package:cloud_firestore/cloud_firestore.dart';

class TopAttendee {
  final String name;
  final int count;

  const TopAttendee({required this.name, required this.count});

  factory TopAttendee.fromFirestore(Map<String, dynamic> data) {
    return TopAttendee(
      name: data['name'] as String? ?? 'Desconocido',
      count: (data['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class LastSessionInfo {
  final int attended;
  final String session; // 'AM' or 'PM'
  final String date; // 'YYYY-MM-DD'

  const LastSessionInfo({
    required this.attended,
    required this.session,
    required this.date,
  });
}

class MonthlyAttendance {
  final String month; // 'ene', 'feb', ...
  final int count;

  const MonthlyAttendance({required this.month, required this.count});
}

class BirthdayPerson {
  final String id;
  final String name;
  final String birthDay;
  final int? day;
  final int? month;
  final String type; // 'Adulto' or 'Niño'
  final String detail;

  const BirthdayPerson({
    required this.id,
    required this.name,
    required this.birthDay,
    this.day,
    this.month,
    required this.type,
    required this.detail,
  });

  factory BirthdayPerson.fromFirestore(
    String id,
    Map<String, dynamic> data,
    String type,
  ) {
    final name =
        data['name'] as String? ?? data['nombre'] as String? ?? 'Sin nombre';

    final rawBirthDay =
        data['birthDay'] ?? data['birthday'] ?? data['fechaNacimiento'];

    String birthDayStr = '';
    Map<String, int>? parsed;

    if (rawBirthDay is String) {
      birthDayStr = rawBirthDay;
      parsed = _parseBirthDay(birthDayStr);
    } else if (rawBirthDay is Timestamp) {
      final dt = rawBirthDay.toDate();
      parsed = {'day': dt.day, 'month': dt.month, 'year': dt.year};
      birthDayStr =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    String detail = '';
    if (type == 'Adulto') {
      final phone = data['phone'] ?? data['telefono'];
      detail = (phone != null && phone.toString().isNotEmpty)
          ? 'Tel: $phone'
          : '';
    } else {
      final classes = data['classes'] ?? data['clases'];
      if (classes is List) {
        detail = classes.join(', ');
      }
    }

    return BirthdayPerson(
      id: id,
      name: name,
      birthDay: birthDayStr,
      day: parsed?['day'],
      month: parsed?['month'],
      type: type,
      detail: detail,
    );
  }

  static Map<String, int>? _parseBirthDay(String birthDay) {
    if (birthDay.isEmpty) return null;

    if (birthDay.contains('/')) {
      final parts = birthDay.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return {'day': day, 'month': month, 'year': year};
        }
      }
    }

    if (birthDay.contains('-')) {
      final dt = DateTime.tryParse(birthDay);
      if (dt != null) {
        return {'day': dt.day, 'month': dt.month, 'year': dt.year};
      }
    }

    return null;
  }
}

class BirthdayReportData {
  final int currentMonth;
  final String monthName;
  final List<BirthdayPerson> birthdays;

  const BirthdayReportData({
    required this.currentMonth,
    required this.monthName,
    required this.birthdays,
  });
}
