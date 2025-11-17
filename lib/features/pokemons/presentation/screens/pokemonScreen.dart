import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:pokemon_collector/features/account/presentation/screens/accountScreen.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/PokemonStat.dart';

/// Экран отображения случайных карт покемонов
class PokemonScreen extends StatefulWidget {
  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Pokemon Cards'),
        leading: IconButton(
          icon: const Icon(Icons.person_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AccountScreen()),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: List.generate(10, (index) {
                  final spacing = MediaQuery.of(context).size.width / 11;

                  return Positioned(
                    left: spacing * (index + 1) - 5,
                    top: 0,
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirection: pi / 2,
                      blastDirectionality: BlastDirectionality.directional,
                      shouldLoop: false,
                      emissionFrequency: 0.03,
                      numberOfParticles: 8,
                      gravity: 0.3,
                      maxBlastForce: 12,
                      minBlastForce: 8,
                      particleDrag: 0.02,
                      colors: const [
                        Colors.red,
                        Colors.blue,
                        Colors.yellow,
                        Colors.green,
                        Colors.purple,
                        Colors.orange,
                        Colors.pink,
                        Colors.amber,
                        Colors.cyan,
                        Colors.lime,
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),

          /// Основной контент
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FlipCard(
                  breathController: _breathController,
                  imageUrl: viewModel.randomPokemonImageUrl,
                  pokemon: viewModel.randomPokemon,
                  isLoading: viewModel.isLoadingRandom,
                  onTap: () => viewModel.loadRandomPokemon(),
                  confetti: _confetti,
                ),

                SizedBox(height: 20),

                if (viewModel.error != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      viewModel.error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Фронтальная сторона карты
class _PokemonCardFront extends StatelessWidget {
  final String imageUrl;
  final String pokemonName;
  final String hp;
  final String type;
  final String category;
  final String rarity;

  const _PokemonCardFront({
    required this.imageUrl,
    required this.pokemonName,
    required this.hp,
    required this.type,
    required this.category,
    required this.rarity,
  });

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.purple;
      case 'rare':
        return Colors.blue;
      case 'uncommon':
        return Colors.green;
      case 'common':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF3B0),
            Color(0xFFFFD56F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade700, width: 4),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 60, left: 8, right: 8, bottom: 90),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    pokemonName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$hp HP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: $type',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Category: $category',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Rarity: ',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRarityColor(rarity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rarity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Переворачивающаяся карта
class _FlipCard extends StatefulWidget {
  final AnimationController breathController;
  final String? imageUrl;
  final dynamic pokemon;
  final bool isLoading;
  final VoidCallback onTap;
  final ConfettiController confetti;

  const _FlipCard({
    required this.breathController,
    required this.imageUrl,
    required this.pokemon,
    required this.isLoading,
    required this.onTap,
    required this.confetti,
  });

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with TickerProviderStateMixin {
  late Animation<double> _breathe;
  late AnimationController _spinController;
  late AnimationController _glowController;

  bool _isSpinning = false;
  bool _isRevealed = false;

  @override
  void initState() {
    super.initState();

    _breathe = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: widget.breathController,
        curve: Curves.easeInOut,
      ),
    );

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _stopSpinAndReveal() {
    setState(() {
      _isSpinning = false;
      _isRevealed = true;
    });
  }

  Future<void> _handleTap() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _isRevealed = false;
    });

    _spinController.forward(from: 0);

    widget.onTap();

    await Future.delayed(const Duration(milliseconds: 5000));

    if (_isSpinning && widget.imageUrl != null) {
      _stopSpinAndReveal();
      widget.confetti.play();
    } else {
      setState(() => _isSpinning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathe,
        _spinController,
        _glowController,
      ]),
      builder: (_, __) {
        final shouldBreathe = !_isSpinning && !_isRevealed;
        final scale = shouldBreathe ? _breathe.value : 1.0;

        final t = _spinController.value;
        final curvedValue = t * t;
        final spinAngle =
        _isSpinning ? curvedValue * 12 * 2 * pi : 0.0;

        final glowIntensity = _isRevealed ? _glowController.value : 0.0;
        final showFront = _isRevealed && !_isSpinning;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(scale)
            ..rotateY(spinAngle),
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              width: 300,
              height: 480,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                  if (_isRevealed)
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5 * glowIntensity),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: showFront &&
                    widget.imageUrl != null &&
                    widget.pokemon != null
                    ? _PokemonCardFront(
                  imageUrl: widget.imageUrl!,
                  pokemonName: widget.pokemon.name ?? 'Unknown',
                  hp: widget.pokemon.stats.isNotEmpty
                      ? widget.pokemon.stats.firstWhere(
                          (s) => s.name == 'hp',
                          orElse: () => PokemonStat(baseStat: 0, effort: 0, name: 'hp'),
                        ).baseStat.toString()
                      : '0',
                  type: widget.pokemon.types.isNotEmpty
                      ? widget.pokemon.types.join(', ')
                      : 'Unknown',
                  category: widget.pokemon.category,
                  rarity: widget.pokemon.rarity,
                )
                    : Image.asset(
                  'assets/images/pokemonBack.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
