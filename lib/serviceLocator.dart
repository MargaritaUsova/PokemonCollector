import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokemon_collector/features/pokemons/domain/pokemonRepository.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/data/pokemonRemoteDataSource.dart';
import 'package:pokemon_collector/features/auth/presentation/viewModels/auth_view_model.dart';
import 'package:pokemon_collector/features/auth/data/services/google_auth_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Pokemon dependencies
  getIt.registerLazySingleton(() => PokemonRemoteDataSource());
  getIt.registerLazySingleton(() => PokemonRepository(remoteDataSource: getIt<PokemonRemoteDataSource>()));
  getIt.registerFactory(() => PokemonViewModel(repository: getIt<PokemonRepository>()));

  // Auth dependencies
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => GoogleAuthService(getIt<FirebaseAuth>()));
  getIt.registerFactory(() => AuthViewModel(getIt<GoogleAuthService>()));
}
