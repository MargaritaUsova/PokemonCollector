import 'package:flutter/cupertino.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/domain/pokemonRepository.dart';

class PokemonViewModel extends ChangeNotifier {
  final PokemonRepository repository;
  List<Pokemon> pokemons = [];
  bool isLoading = false;
  String? error;

  PokemonViewModel({required this.repository});

  Future<void> loadPokemons() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      pokemons = await repository.getPokemons(pageSize: 20);
    } catch(e, stack) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}