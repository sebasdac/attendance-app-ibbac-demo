class KidsClass {
  final String id;
  final String name;

  const KidsClass({required this.id, required this.name});

  factory KidsClass.fromFirestore(String id, Map<String, dynamic> data) {
    return KidsClass(id: id, name: data['name'] as String? ?? 'Sin nombre');
  }

  Map<String, dynamic> toMap() {
    return {'name': name};
  }
}
