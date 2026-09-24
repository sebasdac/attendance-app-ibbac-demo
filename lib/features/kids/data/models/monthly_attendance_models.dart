class SundayStat {
  final DateTime date;
  final String dateStr;
  final int amCount;
  final int pmCount;
  final int totalCount;
  final List<String> amAttendees;
  final List<String> pmAttendees;

  SundayStat({
    required this.date,
    required this.dateStr,
    required this.amCount,
    required this.pmCount,
    required this.totalCount,
    required this.amAttendees,
    required this.pmAttendees,
  });
}

class KidAttendeeStat {
  final String kidName;
  final int attendedSundays;
  final int totalSundays;
  final double percentage;

  KidAttendeeStat({
    required this.kidName,
    required this.attendedSundays,
    required this.totalSundays,
    required this.percentage,
  });
}

class KidMonthlyDetail {
  final String kidName;
  final int attendedSundays;
  final int totalSundays;
  final double percentage;
  final Map<String, bool> sundayRecords; // "YYYY-MM-DD" => bool

  KidMonthlyDetail({
    required this.kidName,
    required this.attendedSundays,
    required this.totalSundays,
    required this.percentage,
    required this.sundayRecords,
  });
}

class MonthlyReportData {
  final String selectedClass;
  final String selectedMonth;
  final int year;
  final int totalSundays;
  final int totalAttendance;
  final double averagePerSunday;
  final List<SundayStat> weeklyStats;
  final List<KidAttendeeStat> topAttendees;
  final Map<String, KidMonthlyDetail> attendanceByKid;

  MonthlyReportData({
    required this.selectedClass,
    required this.selectedMonth,
    required this.year,
    required this.totalSundays,
    required this.totalAttendance,
    required this.averagePerSunday,
    required this.weeklyStats,
    required this.topAttendees,
    required this.attendanceByKid,
  });
}
