import 'package:flutter/cupertino.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/domain/pokemonRepository.dart';
import 'package:pokemon_tcg/pokemon_tcg.dart';

class PokemonViewModel extends ChangeNotifier {
  final PokemonRepository repository;
  List<Pokemon> pokemons = [];
  List<CardSet> sets = [];
  List<String> types = [];
  List<String> subtypes = [];
  List<String> supertypes = [];
  List<String> rarities = [];
  bool isLoading = false;
  String? error;

  PokemonViewModel({required this.repository});

  /// Загрузить карты
  Future<void> loadPokemons({int pageSize = 20}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      pokemons = await repository.getPokemons(pageSize: pageSize);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Получить конкретную карту
  Future<Pokemon?> getCard(String cardId) async {
    try {
      return await repository.getCard(cardId);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Получить карты из набора
  Future<void> loadCardsForSet(String setId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      pokemons = await repository.getCardsForSet(setId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Загрузить наборы
  Future<void> loadSets() async {
    try {
      sets = await repository.getSets();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Загрузить метаданные (типы, подтипы, редкости)
  Future<void> loadMetadata() async {
    try {
      final futures = await Future.wait([
        repository.getTypes(),
        repository.getSubtypes(),
        repository.getSupertypes(),
        repository.getRarities(),
      ]);
      
      types = futures[0];
      subtypes = futures[1];
      supertypes = futures[2];
      rarities = futures[3];
      
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Очистить ошибку
  void clearError() {
    error = null;
    notifyListeners();
  }

  /// Сбросить состояние
  void reset() {
    pokemons.clear();
    sets.clear();
    types.clear();
    subtypes.clear();
    supertypes.clear();
    rarities.clear();
    error = null;
    isLoading = false;
    notifyListeners();
  }
}