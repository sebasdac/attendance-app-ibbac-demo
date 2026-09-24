import 'package:flutter/foundation.dart';
import '../data/models/kids_class_model.dart';
import '../data/repositories/kids_repository.dart';

class KidsController extends ChangeNotifier {
  final KidsRepository _repository;

  bool _isLoading = true;
  String? _errorMessage;
  List<KidsClass> _classes = [];

  KidsController({KidsRepository? repository})
    : _repository = repository ?? KidsRepository() {
    fetchClasses();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<KidsClass> get classes => _classes;

  Future<void> fetchClasses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _classes = await _repository.fetchClasses();
    } catch (e) {
      _errorMessage = 'Error al cargar las clases';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
