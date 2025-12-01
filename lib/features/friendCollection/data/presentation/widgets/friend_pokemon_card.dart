import 'package:flutter/material.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/core/theme/app_theme.dart';
import '../viewmodels/friend_collection_viewmodel.dart';
import 'pokemon_detail_modal.dart';

class FriendPokemonCard extends StatefulWidget {
  final String pokemonId;
  final FriendCollectionViewModel viewModel;
  final VoidCallback onTap;

  const FriendPokemonCard({
    required this.pokemonId,
    required this.viewModel,
    required this.onTap,
  });

  @override
  State<FriendPokemonCard> createState() => _FriendPokemonCardState();
}

class _FriendPokemonCardState extends State<FriendPokemonCard> {
  Pokemon? _pokemon;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  Future<void> _loadPokemon() async {
    try {
      final pokemon = await widget.viewModel.getPokemonById(widget.pokemonId);
      if (!mounted) return;
      setState(() {
        _pokemon = pokemon;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pokemon: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 8),
              Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_pokemon == null) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: theme.colorScheme.outline.withOpacity(0.5),
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'Не удалось загрузить',
                style: TextStyle(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => PokemonDetailModal.show(context, _pokemon!),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorderColor(context), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Имя покемона
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              ),
              child: Text(
                _pokemon!.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            // Изображение с лоадером
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Image.network(
                  _pokemon!.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.catching_pokemon,
                    size: 50,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            // Подсказка для длинного нажатия
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Удерживайте для деталей',
                style: TextStyle(
                  fontSize: 8,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
