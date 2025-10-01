import 'package:pokemon_collector/core/network_service.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';

class PokemonRepository {
  final NetworkService service;

  PokemonRepository({required this.service});

  Future<List<Pokemon>> getPokemons({int pageSize = 20}) {
    return service.fetchPokemons(pageSize: pageSize);
  }
}
