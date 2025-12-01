import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/fullscreen_pokemon_card.dart';
import 'fullscreen_card_reveal.dart';

class SmallFlipCard extends StatefulWidget {
  final ConfettiController confetti;
  final PokemonViewModel viewModel;
  final Function(int pokemonId) onPokemonCaught;
  final bool canTakeNewCard;

  const SmallFlipCard({
    Key? key,
    required this.confetti,
    required this.viewModel,
    required this.onPokemonCaught,
    this.canTakeNewCard = true,
  }) : super(key: key);

  @override
  State<SmallFlipCard> createState() => _SmallFlipCardState();
}

class _SmallFlipCardState extends State<SmallFlipCard> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isFlipping = false;
  Pokemon? _currentPokemon;

  late AnimationController _flipController;
  late AnimationController _scaleController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _flipCard() async {
    if (!widget.canTakeNewCard || _isLoading || _isFlipping || widget.viewModel.isLoadingRandom) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isFlipping = true;
    });

    try {
      await _scaleController.forward();
      await _scaleController.reverse();

      final pokemonId = (DateTime.now().millisecondsSinceEpoch % 898) + 1;
      final pokemon = await widget.viewModel.getPokemonById(pokemonId.toString());

      if (!mounted || pokemon == null) return;

      setState(() => _currentPokemon = pokemon);

      await Future.delayed(const Duration(milliseconds: 200));
      _flipController.forward();

      await Future.delayed(const Duration(milliseconds: 600));

      widget.confetti.play();
      _showBigCard(pokemon);

      await Future.delayed(const Duration(milliseconds: 1500));
      await _flipController.reverse();
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFlipping = false;
          _currentPokemon = null;
        });
        _flipController.reset();
      }
    }
  }

  void _showBigCard(Pokemon pokemon) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => FullscreenCardReveal(
          pokemon: pokemon,
          confetti: widget.confetti,
          onComplete: (pokemonId) => widget.onPokemonCaught(pokemonId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canTap = widget.canTakeNewCard && !_isLoading && !_isFlipping;

    return GestureDetector(
      onTap: canTap ? _flipCard : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnimation, _scaleAnimation]),
        builder: (context, child) {
          final flipProgress = _flipAnimation.value;
          final scale = _scaleAnimation.value;

          final showFront = flipProgress < pi / 2;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..scale(scale)
              ..rotateY(flipProgress),
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 180,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isFlipping
                        ? Colors.amber.withOpacity(0.7)
                        : Colors.black.withOpacity(0.3),
                    blurRadius: _isFlipping ? 40 : 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: showFront
                  ? _buildBackSide(theme)
                  : Transform(
                transform: Matrix4.rotationY(pi),
                alignment: Alignment.center,
                child: _buildFrontSide(theme),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackSide(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade700, width: 3),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/pokemonBack.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.blue.shade700],
                  ),
                ),
              ),
            ),
            if (_isLoading && !_isFlipping)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withOpacity(0.3),
                      Colors.orange.withOpacity(0.3),
                    ],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontSide(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          border: Border.all(color: Colors.amber.shade700, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentPokemon?.imageUrl != null)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.shade100,
                      Colors.white,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    _currentPokemon!.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.catching_pokemon,
                      size: 80,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_currentPokemon?.name != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _currentPokemon!.name!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                    (index) => Icon(
                  Icons.star,
                  color: Colors.amber.shade600,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
