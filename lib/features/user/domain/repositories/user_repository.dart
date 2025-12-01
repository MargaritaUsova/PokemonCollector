import 'package:pokemon_collector/features/user/domain/entities/user_data_entity.dart';

abstract class UserRepository {
  Future<UserDataEntity?> getUserData(String userId);
  Future<void> savePokemon(String userId, int pokemonId);
  Future<void> updateCardTimestamp(String userId);
  Stream<UserDataEntity?> watchUserData(String userId);
}
