import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';

class SmallFlipCard extends StatefulWidget {
  final AnimationController breathController;
  final ConfettiController confetti;
  final PokemonViewModel viewModel;
  final Function(int pokemonId) onPokemonCaught;
  final bool canTakeNewCard;

  const SmallFlipCard({
    Key? key,
    required this.breathController,
    required this.confetti,
    required this.viewModel,
    required this.onPokemonCaught,
    required this.canTakeNewCard,
  }) : super(key: key);

  @override
  _SmallFlipCardState createState() => _SmallFlipCardState();
}

class _SmallFlipCardState extends State<SmallFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _glowAnimation;

  bool _isFlipping = false;
  Pokemon? _caughtPokemon;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  Future<void> _flipCard() async {
    if (_isFlipping || widget.viewModel.isLoadingRandom) {
      return;
    }

    setState(() => _isFlipping = true);

    try {
      await widget.viewModel.loadRandomPokemon().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Pokemon loading timeout');
        },
      );

      if (widget.viewModel.randomPokemon == null) {
        if (mounted) setState(() => _isFlipping = false);
        return;
      }

      final pokemonToSave = widget.viewModel.randomPokemon!;

      if (!mounted) return;

      setState(() => _caughtPokemon = pokemonToSave);

      _controller.forward();

      await Future.delayed(const Duration(milliseconds: 5000));

      widget.confetti.play();

      await Future.delayed(const Duration(milliseconds: 3000));
    } catch (e) {
      if (mounted) setState(() => _isFlipping = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, widget.breathController]),
        builder: (context, child) {
          final angle = _flipAnimation.value * pi;
          final glowIntensity = _glowAnimation.value;

          final breathScale = _isFlipping
              ? 1.0
              : 1.0 + (widget.breathController.value * 0.05);

          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scale(breathScale)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  if (_isFlipping && glowIntensity > 0)
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(glowIntensity * 0.8),
                      blurRadius: 30 * glowIntensity,
                      spreadRadius: 5 * glowIntensity,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: angle < pi / 2
                    ? _buildFrontCard(theme)
                    : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildBackCard(theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(ThemeData theme) {
    return Image.asset(
      'assets/images/pokemonBack.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.catching_pokemon,
                  size: 40,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Нажми!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackCard(ThemeData theme) {
    if (widget.viewModel.isLoadingRandom || _caughtPokemon == null) {
      return Container(
        color: theme.colorScheme.surface,
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Text(
              _caughtPokemon!.name.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.network(
                    _caughtPokemon!.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_caughtPokemon!.types.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: _caughtPokemon!.types.map((type) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.purple;
      case 'ice':
        return Colors.cyan;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown;
      case 'fairy':
        return Colors.pink;
      case 'normal':
        return Colors.grey;
      case 'fighting':
        return Colors.red;
      case 'flying':
        return Colors.lightBlue;
      case 'poison':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}
