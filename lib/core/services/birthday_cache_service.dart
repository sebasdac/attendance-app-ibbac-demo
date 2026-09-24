import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedBirthdayMember {
  final String id;
  final String name;
  final String birthDay;
  final String type; // 'adult' | 'kid'

  CachedBirthdayMember({
    required this.id,
    required this.name,
    required this.birthDay,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDay': birthDay,
    'type': type,
  };

  factory CachedBirthdayMember.fromJson(Map<String, dynamic> json) =>
      CachedBirthdayMember(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        birthDay: json['birthDay']?.toString() ?? '',
        type: json['type']?.toString() ?? 'adult',
      );
}

class BirthdayCacheService {
  static const String _cacheKey = 'cached_birthdays_data_v1';
  static const String _lastSyncKey = 'last_birthday_sync_date';

  final FirebaseFirestore _firestore;

  BirthdayCacheService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Syncs birthdays from Firestore to local SharedPreferences.
  /// Runs only once per day unless [forceSync] is true.
  /// If [isTeacher] is true, fetches ONLY `kids` collection.
  /// If [isTeacher] is false (Admin), fetches BOTH `persons` and `kids`.
  Future<void> syncBirthdaysFromFirestore({
    required bool isTeacher,
    bool forceSync = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastSync = prefs.getString(_lastSyncKey);

    if (!forceSync && lastSync == todayStr && prefs.containsKey(_cacheKey)) {
      // Already synced today
      return;
    }

    final List<CachedBirthdayMember> members = [];

    // 1. Fetch Kids collection
    try {
      final kidsSnap = await _firestore.collection('kids').get();
      for (final doc in kidsSnap.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        final rawBirth = data['birthDay'] ?? data['birthday'];
        final birthStr = _formatRawBirthday(rawBirth);

        if (name.isNotEmpty && birthStr.isNotEmpty) {
          members.add(
            CachedBirthdayMember(
              id: doc.id,
              name: name,
              birthDay: birthStr,
              type: 'kid',
            ),
          );
        }
      }
    } catch (_) {
      // Continue if kids fetch fails
    }

    // 2. Fetch Persons collection if NOT a teacher (Admin profile)
    if (!isTeacher) {
      try {
        final personsSnap = await _firestore.collection('persons').get();
        for (final doc in personsSnap.docs) {
          final data = doc.data();
          final name = data['name'] as String? ?? '';
          final rawBirth = data['birthDay'] ?? data['birthday'];
          final birthStr = _formatRawBirthday(rawBirth);

          if (name.isNotEmpty && birthStr.isNotEmpty) {
            members.add(
              CachedBirthdayMember(
                id: doc.id,
                name: name,
                birthDay: birthStr,
                type: 'adult',
              ),
            );
          }
        }
      } catch (_) {
        // Continue if persons fetch fails
      }
    }

    // Save to SharedPreferences with name/id deduplication
    final Map<String, CachedBirthdayMember> uniqueMap = {};
    for (final m in members) {
      final normName = _normalizeName(m.name);
      if (!uniqueMap.containsKey(normName) && !uniqueMap.containsKey(m.id)) {
        uniqueMap[normName] = m;
      }
    }

    final jsonList = uniqueMap.values.map((m) => m.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
    await prefs.setString(_lastSyncKey, todayStr);
  }

  /// Adds a single newly registered member to the local cache immediately
  /// without re-fetching all records from Firestore.
  Future<void> addMemberToCache({
    required String name,
    required String birthDay,
    required String type, // 'adult' | 'kid'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CachedBirthdayMember> members = await getCachedMembers();

    final normName = _normalizeName(name);
    // Don't add duplicate if name already exists
    if (!members.any((m) => _normalizeName(m.name) == normName)) {
      members.add(
        CachedBirthdayMember(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          birthDay: birthDay,
          type: type,
        ),
      );

      final jsonList = members.map((m) => m.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    }
  }

  /// Gets all cached members from SharedPreferences.
  Future<List<CachedBirthdayMember>> getCachedMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cacheKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      final list = decoded
          .whereType<Map>()
          .map(
            (item) =>
                CachedBirthdayMember.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();

      // Ensure unique by normalized name
      final Map<String, CachedBirthdayMember> uniqueMap = {};
      for (final m in list) {
        final norm = _normalizeName(m.name);
        if (!uniqueMap.containsKey(norm)) {
          uniqueMap[norm] = m;
        }
      }
      return uniqueMap.values.toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns cached members who celebrate their birthday today.
  Future<List<CachedBirthdayMember>> getTodayBirthdayMembers() async {
    final members = await getCachedMembers();
    final today = DateTime.now();

    return members.where((m) {
      final parsed = _parseBirthDay(m.birthDay);
      if (parsed == null) return false;
      return parsed['month'] == today.month && parsed['day'] == today.day;
    }).toList();
  }

  static String _normalizeName(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Formats raw birthDay input (String or Timestamp) to `dd/mm/yyyy`
  String _formatRawBirthday(dynamic raw) {
    if (raw == null) return '';
    if (raw is Timestamp) {
      final dt = raw.toDate();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    return raw.toString().trim();
  }

  /// Parses day and month from a birthDay string (`dd/mm/yyyy` or `yyyy-mm-dd`)
  static Map<String, int>? _parseBirthDay(String birthDay) {
    if (birthDay.isEmpty) return null;

    if (birthDay.contains('/')) {
      final parts = birthDay.split('/');
      if (parts.length >= 2) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (day != null && month != null) {
          return {'day': day, 'month': month};
        }
      }
    }

    if (birthDay.contains('-')) {
      final dt = DateTime.tryParse(birthDay);
      if (dt != null) {
        return {'day': dt.day, 'month': dt.month};
      }
    }

    return null;
  }
}
