import 'package:get_it/get_it.dart';
import 'package:pokemon_collector/features/pokemons/domain/pokemonRepository.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/auth/presentation/viewModels/authViewModel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pokemon_tcg/pokemon_tcg.dart';
import 'package:pokemon_collector/features/pokemons/data/pokemonRemoteDataSource.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  final apiKey = dotenv.env['POKEMON_TCG_API_KEY'] ?? '';
  getIt.registerLazySingleton(() => PokemonTcgApi(apiKey: apiKey));
  getIt.registerLazySingleton(() => PokemonRemoteDataSource());

  getIt.registerLazySingleton(() => PokemonRepository(remoteDataSource: getIt<PokemonRemoteDataSource>()));
  getIt.registerFactory(() => PokemonViewModel(repository: getIt<PokemonRepository>()));
  getIt.registerFactory(() => AuthViewModel());

}
