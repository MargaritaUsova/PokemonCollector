import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pokemon_collector/features/pokemons/presentation/screens/pokemonScreen.dart';
import 'package:pokemon_collector/features/auth/presentation/screens/authScreen.dart';
import 'package:pokemon_collector/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_collector/serviceLocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pokemon_collector/core/theme/app_theme.dart';
import 'features/account/data/repositories/friend_repository_impl.dart';
import 'features/account/presentation/viewmodels/account_viewmodel.dart';
import 'features/auth/presentation/viewModels/auth_view_model.dart';
import 'features/friendCollection/data/presentation/viewmodels/friend_collection_viewmodel.dart';
import 'features/friendCollection/data/repositories/friend_collection_repository_impl.dart';

import 'features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

  await dotenv.load(fileName: '.env');
  setupDependencies();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => getIt<PokemonViewModel>()),
        ChangeNotifierProvider(create: (_) => getIt<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AccountViewModel(FriendRepositoryImpl()),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final pokemonViewModel = context.read<PokemonViewModel>();
            final repository = FriendCollectionRepositoryImpl(pokemonViewModel);
            return FriendCollectionViewModel(repository);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Pokemon Collector',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return PokemonScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeData get currentTheme {
    if (_themeMode == ThemeMode.light) {
      return AppTheme.lightTheme;
    } else if (_themeMode == ThemeMode.dark) {
      return AppTheme.darkTheme;
    } else {
      return AppTheme.lightTheme;
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}
