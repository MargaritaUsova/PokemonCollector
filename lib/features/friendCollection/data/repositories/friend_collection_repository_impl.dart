import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import '../../domain/repositories/friend_collection_repository.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';

class FriendCollectionRepositoryImpl implements FriendCollectionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PokemonViewModel _pokemonViewModel;

  FriendCollectionRepositoryImpl(this._pokemonViewModel);

  @override
  Future<List<String>> getFriendCollection(String friendId) async {
    final doc = await _firestore.collection('users').doc(friendId).get();
    final data = doc.data();
    final pokemons = List<String>.from(data?['pokemons'] ?? []);
    return pokemons.reversed.toList();
  }

  @override
  Future<List<String>> getMyCollection(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    return List<String>.from(data?['pokemons'] ?? []);
  }

  @override
  Future<void> sendTradeRequest(
      String fromUserId,
      String toUserId,
      String myCardId,
      String friendCardId,
      ) async {
    await _firestore.collection('tradeRequests').add({
      'from': fromUserId,
      'to': toUserId,
      'fromCard': myCardId,
      'toCard': friendCardId,
      'status': 'pending',
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Future<Pokemon?> getPokemonById(String pokemonId) async {
    return await _pokemonViewModel.getPokemonById(pokemonId);
  }
}
