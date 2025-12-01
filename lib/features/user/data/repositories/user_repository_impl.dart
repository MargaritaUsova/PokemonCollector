import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokemon_collector/core/services/firestore_service.dart';
import 'package:pokemon_collector/features/user/domain/entities/user_data_entity.dart';
import 'package:pokemon_collector/features/user/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirestoreService firestoreService;
  final FirebaseFirestore firestore;

  UserRepositoryImpl(this.firestoreService, this.firestore);

  @override
  Future<UserDataEntity?> getUserData(String userId) async {
    try {
      final doc = await firestoreService.getDocument('users', userId);

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      return UserDataEntity.fromMap(data, DateTime.now());
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  @override
  Future<void> savePokemon(String userId, int pokemonId) async {
    try {
      await firestoreService.runTransaction((transaction) async {
        final docRef = firestore.collection('users').doc(userId);
        final doc = await transaction.get(docRef);
        final data = doc.data();
        final currentPokemons = List<String>.from(data?['pokemons'] ?? []);

        if (!currentPokemons.contains(pokemonId.toString())) {
          transaction.update(docRef, {
            'pokemons': FieldValue.arrayUnion([pokemonId.toString()]),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to save pokemon: $e');
    }
  }

  @override
  Future<void> updateCardTimestamp(String userId) async {
    try {
      await firestoreService.updateDocument('users', userId, {
        'lastCardReceived': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update timestamp: $e');
    }
  }

  @override
  Stream<UserDataEntity?> watchUserData(String userId) {
    return firestoreService.watchDocument('users', userId).map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return null;
      return UserDataEntity.fromMap(data, DateTime.now());
    });
  }
}
