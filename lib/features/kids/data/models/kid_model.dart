import 'package:cloud_firestore/cloud_firestore.dart';

class KidModel {
  final String id;
  final String name;
  final String birthDay;
  final List<String> classes;
  final bool isKid;
  final bool isNew;
  final String comments;
  final DateTime? createdAt;

  const KidModel({
    required this.id,
    required this.name,
    required this.birthDay,
    required this.classes,
    this.isKid = true,
    this.isNew = false,
    this.comments = '',
    this.createdAt,
  });

  factory KidModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawClasses = data['classes'];
    List<String> parsedClasses = [];
    if (rawClasses is List) {
      parsedClasses = rawClasses.map((e) => e.toString()).toList();
    }

    DateTime? created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    return KidModel(
      id: id,
      name: data['name'] as String? ?? '',
      birthDay: data['birthDay'] as String? ?? '',
      classes: parsedClasses,
      isKid: data['isKid'] as bool? ?? true,
      isNew: data['isNew'] as bool? ?? false,
      comments: data['comments'] as String? ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthDay': birthDay,
      'classes': classes,
      'isKid': true,
      'isNew': isNew,
      'comments': comments,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
