import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/data/pokemonRemoteDataSource.dart';

class PokemonRepository {
  final PokemonRemoteDataSource remoteDataSource;

  PokemonRepository({required this.remoteDataSource});

  List<Pokemon>? _cachedPokemons;
  DateTime? _cacheTime;
  final Duration _cacheDuration = Duration(minutes: 5);

  bool get _isCacheValid {
    if (_cachedPokemons == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  Future<List<Pokemon>> getPokemons({int pageSize = 20, int offset = 0}) async {
    if (_isCacheValid && _cachedPokemons != null && offset == 0) {
      return _cachedPokemons!;
    }

    try {
      final pokemons = await remoteDataSource.getPokemons(pageSize: pageSize, offset: offset);
      if (offset == 0) {
        _cachedPokemons = pokemons;
        _cacheTime = DateTime.now();
      }
      return pokemons;
    } catch (e) {
      print('Error fetching pokemons: $e');
      return [];
    }
  }

  /// Получить случайного покемона
  Future<Pokemon?> getRandomPokemon() async {
    try {
      return await remoteDataSource.getRandomPokemon();
    } catch (e, stackTrace) {
      print('Error fetching random pokemon: $e');
      return null;
    }
  }

  /// Очистить кеш
  void clearCache() {
    _cachedPokemons = null;
    _cacheTime = null;
  }

  /// Получить одного покемона по ID
  Future<Pokemon?> getPokemonById(String id) {
    return remoteDataSource.getPokemonById(id);
  }

  /// Получить типы покемонов
  Future<List<String>> getTypes() {
    return remoteDataSource.getTypes();
  }
}
