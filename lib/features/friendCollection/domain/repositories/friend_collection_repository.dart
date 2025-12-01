import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';

abstract class FriendCollectionRepository {
  Future<List<String>> getFriendCollection(String friendId);
  Future<List<String>> getMyCollection(String userId);
  Future<void> sendTradeRequest(
      String fromUserId,
      String toUserId,
      String myCardId,
      String friendCardId,
      );
  Future<Pokemon?> getPokemonById(String pokemonId);
}
