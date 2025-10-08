import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pokemon_collector/features/pokemons/presentation/screens/pokemonScreen.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_collector/serviceLocator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  setupDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<PokemonViewModel>()),
      ],
      child: MaterialApp(
        title: 'Pokemon App',
        home: Pokemonscreen(),
      ),
    );
  }
}
// }
