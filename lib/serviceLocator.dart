import 'package:get_it/get_it.dart';
import 'package:pokemon_collector/core/api_endpoints.dart';
import 'package:pokemon_collector/core/network_client.dart';
import 'package:pokemon_collector/core/network_service.dart';
import 'package:pokemon_collector/features/pokemons/domain/pokemonRepository.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton(() => NetworkClient(baseUrl: pokemonBaseUrl));
  getIt.registerLazySingleton(() => NetworkService(client: getIt<NetworkClient>()));

  getIt.registerLazySingleton(() => PokemonRepository(service: getIt<NetworkService>()));
  getIt.registerFactory(() => PokemonViewModel(repository: getIt<PokemonRepository>()));

}
