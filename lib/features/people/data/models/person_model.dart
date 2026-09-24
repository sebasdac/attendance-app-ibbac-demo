import 'package:cloud_firestore/cloud_firestore.dart';

class PersonModel {
  final String id;
  final String name;
  final String phone;
  final String birthDay;
  final bool isNew;
  final DateTime? createdAt;

  const PersonModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.birthDay,
    this.isNew = false,
    this.createdAt,
  });

  factory PersonModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? createdAtDate;
    final rawCreatedAt = data['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAtDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAtDate = DateTime.tryParse(rawCreatedAt);
    }

    return PersonModel(
      id: id,
      name: data['name'] as String? ?? '',
      phone: (data['phone'] ?? '').toString(),
      birthDay: data['birthDay'] as String? ?? '',
      isNew: data['isNew'] as bool? ?? false,
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'birthDay': birthDay,
      'isNew': isNew,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  PersonModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? birthDay,
    bool? isNew,
    DateTime? createdAt,
  }) {
    return PersonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      birthDay: birthDay ?? this.birthDay,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
