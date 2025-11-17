import 'package:flutter/cupertino.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/domain/pokemonRepository.dart';
import 'dart:math';

class PokemonViewModel extends ChangeNotifier {
  final PokemonRepository repository;

  Pokemon? randomPokemon;
  String? randomPokemonImageUrl;

  List<Pokemon> pokemons = [];
  List<String> types = [];

  bool isLoadingRandom = false;
  bool isLoadingList = false;
  String? error;

  PokemonViewModel({required this.repository});

  /// Загрузить случайного покемона
  Future<void> loadRandomPokemon() async {
    isLoadingRandom = true;
    error = null;
    notifyListeners();

    try {
      final pokemon = await repository.getRandomPokemon();
      
      if (pokemon != null) {
        randomPokemon = pokemon;
        randomPokemonImageUrl = randomPokemon!.imageUrl;
      } else {
        error = 'Не удалось загрузить покемона.';
      }
    } catch (e, stackTrace) {
      error = 'Ошибка загрузки: $e';
      print('Error loading random pokemon: $e');
    } finally {
      isLoadingRandom = false;
      notifyListeners();
    }
  }

  /// Загрузить список покемонов
  Future<void> loadPokemons({int pageSize = 20}) async {
    isLoadingList = true;
    error = null;
    notifyListeners();

    try {
      pokemons = await repository.getPokemons(pageSize: pageSize);
    } catch (e) {
      error = 'Ошибка загрузки: $e';
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  /// Получить одного покемона по ID
  Future<Pokemon?> getPokemonById(String id) async {
    try {
      return await repository.getPokemonById(id);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Сброс состояния случайного покемона
  void resetRandomPokemon() {
    randomPokemon = null;
    randomPokemonImageUrl = null;
    isLoadingRandom = false;
    notifyListeners();
  }

  /// Полный сброс состояния
  void reset() {
    randomPokemon = null;
    randomPokemonImageUrl = null;
    pokemons.clear();
    types.clear();
    error = null;
    isLoadingRandom = false;
    isLoadingList = false;
    notifyListeners();
  }

  /// Очистить ошибку
  void clearError() {
    error = null;
    notifyListeners();
  }
}
