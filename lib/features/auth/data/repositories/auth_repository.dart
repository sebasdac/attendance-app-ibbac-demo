import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseFirestore _firestore;
  static const String _userKey = 'user';

  AuthRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Authenticate against Firestore `usuarios` collection by email & password.
  Future<UserModel> login(String email, String password) async {
    final cleanEmail = email.trim();

    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: cleanEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw const AuthException('Usuario no encontrado');
      }

      final doc = querySnapshot.docs.first;
      final userData = UserModel.fromFirestore(doc.data(), doc.id);

      if (userData.password != password) {
        throw const AuthException('Contraseña incorrecta');
      }

      // Save user session locally in SharedPreferences
      await saveUserLocally(userData);

      return userData;
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        throw const AuthException(
          'Error de conexión. Verifica tu conexión a internet.',
        );
      }
      throw AuthException('Error de Firebase: ${e.message ?? e.code}');
    } catch (e) {
      throw const AuthException('Hubo un problema al iniciar sesión');
    }
  }

  /// Save logged-in user to local storage.
  Future<void> saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Retrieve cached user from local storage if available.
  Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr == null) return null;

      final Map<String, dynamic> userMap = jsonDecode(userStr);
      final cachedUser = UserModel.fromJson(userMap);

      // Verify user against Firestore to ensure valid session
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: cachedUser.email)
          .where('password', isEqualTo: cachedUser.password)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final updatedUser = UserModel.fromFirestore(doc.data(), doc.id);
        await saveUserLocally(updatedUser);
        return updatedUser;
      } else {
        await clearUserLocally();
        return null;
      }
    } catch (e) {
      await clearUserLocally();
      return null;
    }
  }

  /// Clear local user session on logout.
  Future<void> clearUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
