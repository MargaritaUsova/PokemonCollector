import 'package:pokemon_collector/features/user/domain/repositories/user_repository.dart';

class SavePokemonUseCase {
  final UserRepository repository;

  SavePokemonUseCase(this.repository);

  Future<void> execute(String userId, int pokemonId) async {
    await repository.savePokemon(userId, pokemonId);
  }
}
