import 'package:flutter/material.dart';
import 'package:pokemon_collector/features/auth/presentation/viewModels/authViewModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text('Аккаунт')),
      body: Center(child: ElevatedButton(
        onPressed: () {
          authVM.signOut();
          Navigator.pop(context);
        },
        child: Text('Выйти'),
      )
      ),
    );
  }
}
