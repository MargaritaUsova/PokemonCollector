import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/data/pokemonRemoteDataSource.dart';
import 'package:pokemon_tcg/pokemon_tcg.dart';

class PokemonRepository {
  final PokemonRemoteDataSource remoteDataSource;

  PokemonRepository({required this.remoteDataSource});

  /// Получить список карт
  Future<List<Pokemon>> getPokemons({int pageSize = 20}) {
    return remoteDataSource.getPokemons(pageSize: pageSize);
  }

  /// Получить конкретную карту по ID
  Future<Pokemon?> getCard(String cardId) {
    return remoteDataSource.getCard(cardId);
  }

  /// Получить карты из конкретного набора
  Future<List<Pokemon>> getCardsForSet(String setId) {
    return remoteDataSource.getCardsForSet(setId);
  }

  /// Получить все наборы
  Future<List<CardSet>> getSets() {
    return remoteDataSource.getSets();
  }

  /// Получить конкретный набор
  Future<CardSet?> getSet(String setId) {
    return remoteDataSource.getSet(setId);
  }

  /// Получить типы карт
  Future<List<String>> getTypes() {
    return remoteDataSource.getTypes();
  }

  /// Получить подтипы карт
  Future<List<String>> getSubtypes() {
    return remoteDataSource.getSubtypes();
  }

  /// Получить супертипы карт
  Future<List<String>> getSupertypes() {
    return remoteDataSource.getSupertypes();
  }

  /// Получить редкости карт
  Future<List<String>> getRarities() {
    return remoteDataSource.getRarities();
  }
}
