import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/person_model.dart';

class PeopleRepository {
  final FirebaseFirestore _firestore;

  PeopleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _peopleCollection =>
      _firestore.collection('people');

  /// Fetches all people from Firestore sorted alphabetically by name
  Future<List<PersonModel>> getPeople() async {
    final snapshot = await _peopleCollection.get();
    final people = snapshot.docs
        .map((doc) => PersonModel.fromFirestore(doc.data(), doc.id))
        .toList();

    people.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return people;
  }

  /// Adds a new person to Firestore
  Future<DocumentReference<Map<String, dynamic>>> addPerson({
    required String name,
    required String phone,
    required String birthDay,
    required bool isNew,
  }) async {
    return await _peopleCollection.add({
      'name': name.trim(),
      'phone': phone.trim(),
      'birthDay': birthDay.trim(),
      'isNew': isNew,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates an existing person document in Firestore
  Future<void> updatePerson({
    required String id,
    required String name,
    required String phone,
    required String birthDay,
    required bool isNew,
  }) async {
    await _peopleCollection.doc(id).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'birthDay': birthDay.trim(),
      'isNew': isNew,
    });
  }

  /// Deletes a person from Firestore by document ID
  Future<void> deletePerson(String id) async {
    await _peopleCollection.doc(id).delete();
  }
}
