import 'package:flutter/material.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:provider/provider.dart';

class Pokemonscreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonViewModel>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Ошибка: ${viewModel.error}'),
                  ElevatedButton(
                    onPressed: () => viewModel.loadPokemons(),
                    child: Text('Повторить'),
                  ),
                ],
              ),
            )
          : viewModel.pokemons.isEmpty
          ? const Center(child: Text('Нет покемонов'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.pokemons.length,
        itemBuilder: (_, index) {
          final pokemon = viewModel.pokemons[index];
          return ListTile(
            title: Text(pokemon.name),
            subtitle: Text('HP: ${pokemon.hp}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          viewModel.loadPokemons();
        },
        child: const Icon(Icons.add_circle),
      ),
    );
  }
}
