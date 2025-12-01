import 'package:flutter/material.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/core/theme/app_theme.dart';
import '../../data/models/pokemonModel.dart';

class PokemonCardWithLoader extends StatelessWidget {
  final Pokemon pokemon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PokemonCardWithLoader({
    required this.pokemon,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
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
                pokemon.name.toUpperCase(),
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
                  pokemon.imageUrl,
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
