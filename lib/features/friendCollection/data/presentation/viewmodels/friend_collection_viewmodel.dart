import 'package:flutter/foundation.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import '../../../domain/repositories/friend_collection_repository.dart';

class FriendCollectionViewModel extends ChangeNotifier {
  final FriendCollectionRepository _repository;

  FriendCollectionViewModel(this._repository);

  List<String> _friendPokemonIds = [];
  List<String> _myPokemonIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;
  String? _selectedFriendCard;

  List<String> get friendPokemonIds => _friendPokemonIds;
  List<String> get myPokemonIds => _myPokemonIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get selectedFriendCard => _selectedFriendCard;

  Future<void> loadFriendCollection(String friendId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _friendPokemonIds = await _repository.getFriendCollection(friendId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка загрузки: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyCollection(String userId) async {
    try {
      _myPokemonIds = await _repository.getMyCollection(userId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка загрузки вашей коллекции: $e';
      notifyListeners();
    }
  }

  void selectCard(String? cardId) {
    _selectedFriendCard = cardId;
    notifyListeners();
  }

  Future<void> sendTradeRequest(
      String fromUserId,
      String toUserId,
      String myCardId,
      String friendCardId,
      ) async {
    try {
      await _repository.sendTradeRequest(fromUserId, toUserId, myCardId, friendCardId);
      _selectedFriendCard = null;
      _successMessage = 'Предложение обмена отправлено!';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка: $e';
      notifyListeners();
    }
  }

  Future<Pokemon?> getPokemonById(String pokemonId) async {
    return await _repository.getPokemonById(pokemonId);
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
