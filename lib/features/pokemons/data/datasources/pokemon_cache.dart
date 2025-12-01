import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';

class PokemonCache {
  static final PokemonCache _instance = PokemonCache._internal();
  factory PokemonCache() => _instance;
  PokemonCache._internal();

  final Map<String, Pokemon> _cache = {};

  Pokemon? get(String id) => _cache[id];

  void set(String id, Pokemon pokemon) {
    _cache[id] = pokemon;
  }

  bool contains(String id) => _cache.containsKey(id);

  void clear() {
    _cache.clear();
  }

  int get size => _cache.length;
}
