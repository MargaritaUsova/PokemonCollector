import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/small_flip_card.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/confetti_overlay.dart';

class NewPlayerView extends StatefulWidget {
  final ConfettiController confetti;
  final PokemonViewModel viewModel;
  final Function(int pokemonId) onPokemonCaught;
  final bool canTakeNewCard;

  const NewPlayerView({
    Key? key,
    required this.confetti,
    required this.viewModel,
    required this.onPokemonCaught,
    this.canTakeNewCard = true,
  }) : super(key: key);

  @override
  State<NewPlayerView> createState() => _NewPlayerViewState();
}

class _NewPlayerViewState extends State<NewPlayerView> with TickerProviderStateMixin {
  bool _hasCaughtFirstCard = false;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canTakeCard = widget.canTakeNewCard && !_hasCaughtFirstCard;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.85),
                theme.colorScheme.secondary.withOpacity(0.85),
              ],
            ),
          ),
        ),

        // Конфетти
        ConfettiOverlay(confetti: widget.confetti),

        // Основной контент
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasCaughtFirstCard) ...[

                const Text(
                  'Добро пожаловать!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Нажми на карту, чтобы получить\nсвоего первого покемона!',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
              ] else ...[
                // После первой карты
                const Icon(
                  Icons.celebration,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  '🎉 Первый покемон получен!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Твой первый покемон уже в коллекции!\nЗакрой большую карту чтобы увидеть',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
              ],

              SizedBox(
                height: 310,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (canTakeCard)
                          Container(
                            width: 220 * _pulseAnimation.value,
                            height: 310 * _pulseAnimation.value,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.4 * _glowAnimation.value),
                                  blurRadius: 40 * _glowAnimation.value,
                                  spreadRadius: 10 * _glowAnimation.value,
                                ),
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.3 * _glowAnimation.value),
                                  blurRadius: 60 * _glowAnimation.value,
                                  spreadRadius: 5 * _glowAnimation.value,
                                ),
                              ],
                            ),
                          ),

                        // Карта
                        Transform.scale(
                          scale: canTakeCard ? _pulseAnimation.value : 1.0,
                          child: Stack(
                            children: [
                              Opacity(
                                opacity: canTakeCard ? 1.0 : 0.6,
                                child: IgnorePointer(
                                  ignoring: !canTakeCard,
                                  child: SizedBox(
                                    width: 220,
                                    height: 310,
                                    child: SmallFlipCard(
                                      confetti: widget.confetti,
                                      viewModel: widget.viewModel,
                                      canTakeNewCard: canTakeCard,
                                      onPokemonCaught: (int pokemonId) {
                                        setState(() => _hasCaughtFirstCard = true);
                                        widget.onPokemonCaught(pokemonId);
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // Замок
                              if (!canTakeCard)
                                Positioned.fill(
                                  child: Container(
                                    width: 220,
                                    height: 310,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Ошибка
              if (widget.viewModel.error != null)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.viewModel.error!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
