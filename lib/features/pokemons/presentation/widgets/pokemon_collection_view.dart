import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/small_flip_card.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/small_pokemon_card.dart';
import 'dart:async';

class PokemonCollectionView extends StatefulWidget {
  final List<String> pokemonIds;
  final PokemonViewModel viewModel;
  final ConfettiController confetti;
  final Function(int pokemonId) onPokemonCaught;
  final DateTime? nextCardTime;
  final bool canTakeNewCard;

  const PokemonCollectionView({
    Key? key,
    required this.pokemonIds,
    required this.viewModel,
    required this.confetti,
    required this.onPokemonCaught,
    this.nextCardTime,
    this.canTakeNewCard = false,
  }) : super(key: key);

  @override
  State<PokemonCollectionView> createState() => _PokemonCollectionViewState();
}

class _PokemonCollectionViewState extends State<PokemonCollectionView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Timer _timerTick;
  Duration _remainingTime = Duration.zero;
  bool _isProcessingNewCard = false;

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

    _updateRemainingTime();
    _startTimer();
  }

  void _updateRemainingTime() {
    if (widget.nextCardTime != null) {
      final now = DateTime.now();
      if (now.isBefore(widget.nextCardTime!)) {
        _remainingTime = widget.nextCardTime!.difference(now);
      } else {
        _remainingTime = Duration.zero;
      }
    }
  }

  void _startTimer() {
    _timerTick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _updateRemainingTime());
      }
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _timerTick.cancel();
    super.dispose();
  }

  void _showPokemonDetails(BuildContext context, dynamic pokemon) {
    if (pokemon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Покемон не найден')),
      );
      return;
    }

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Image
              Center(
                child: Image.network(
                  pokemon.imageUrl ?? '',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.catching_pokemon,
                    size: 100,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                (pokemon.name ?? 'Unknown').toUpperCase(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Stats header
              const Text(
                'Характеристики',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Stats list
              if ((pokemon.stats ?? []).isNotEmpty)
                ...((pokemon.stats ?? []).map<Widget>((dynamic stat) => _buildStatBar(
                  (stat.name ?? 'Unknown').toUpperCase(),
                  stat.baseStat ?? 0,
                  255,
                  _getStatColor(stat.name ?? ''),
                )))
              else
                const Text('Нет данных о характеристиках'),
              const SizedBox(height: 16),
              // Types
              if ((pokemon.types ?? []).isNotEmpty) ...<Widget>[
                const Text(
                  'Типы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: (pokemon.types ?? [])
                      .map<Widget>((dynamic type) => Chip(
                    label: Text(type ?? 'Unknown'),
                    backgroundColor: _getTypeColor(type ?? ''),
                  ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatBar(String label, int value, int maxValue, Color color) {
    final percentage = value / maxValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                value.toString(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatColor(String statName) {
    switch (statName.toLowerCase()) {
      case 'hp':
        return Colors.red;
      case 'attack':
        return Colors.orange;
      case 'defense':
        return Colors.blue;
      case 'special-attack':
        return Colors.purple;
      case 'special-defense':
        return Colors.green;
      case 'speed':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
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
        return Colors.amber;
      case 'psychic':
        return Colors.purple;
      case 'ice':
        return Colors.cyan;
      case 'dragon':
        return Colors.indigo;
      case 'dark':
        return Colors.brown.shade700;
      case 'fairy':
        return Colors.pink;
      case 'normal':
        return Colors.grey.shade600;
      case 'fighting':
        return Colors.red.shade600;
      case 'flying':
        return Colors.lightBlue;
      case 'poison':
        return Colors.deepPurple;
      case 'ground':
        return Colors.brown.shade400;
      case 'rock':
        return Colors.grey.shade700;
      case 'bug':
        return Colors.lightGreen.shade600;
      case 'ghost':
        return Colors.deepPurple.shade900;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCardHeader() {
    final theme = Theme.of(context);
    final canTakeCard = widget.canTakeNewCard &&
        _remainingTime.inSeconds <= 0 &&
        !_isProcessingNewCard;

    final isWaiting = _remainingTime.inSeconds > 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.secondary.withOpacity(0.85)
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isWaiting ? 'Получи новую карту через' : 'Получи новую карту!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (isWaiting)
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (canTakeCard)
                      Container(
                        width: 200 * _pulseAnimation.value,
                        height: 280 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow
                                  .withOpacity(0.4 * _glowAnimation.value),
                              blurRadius: 40 * _glowAnimation.value,
                              spreadRadius: 10 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: Colors.amber
                                  .withOpacity(0.3 * _glowAnimation.value),
                              blurRadius: 60 * _glowAnimation.value,
                              spreadRadius: 5 * _glowAnimation.value,
                            ),
                          ],
                        ),
                      ),
                    Transform.scale(
                      scale: canTakeCard ? _pulseAnimation.value : 1.0,
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: canTakeCard ? 1.0 : 0.6,
                            child: IgnorePointer(
                              ignoring: !canTakeCard,
                              child: SizedBox(
                                width: 180,
                                height: 260,
                                child: SmallFlipCard(
                                  key: const ValueKey('flip_card_header'),
                                  confetti: widget.confetti,
                                  viewModel: widget.viewModel,
                                  canTakeNewCard: canTakeCard,
                                  onPokemonCaught: (pokemonId) {
                                    setState(() => _isProcessingNewCard = true);
                                    widget.onPokemonCaught(pokemonId);
                                    Future.delayed(const Duration(seconds: 3), () {
                                      if (mounted) {
                                        setState(() => _isProcessingNewCard = false);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (!canTakeCard)
                            Positioned.fill(
                              child: Container(
                                width: 180,
                                height: 260,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayPokemonIds = widget.pokemonIds;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 420,
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildCardHeader(),
            collapseMode: CollapseMode.parallax,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                Icon(
                  Icons.collections,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Твоя коллекция',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Количество покемонов: ${widget.pokemonIds.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: widget.pokemonIds.isEmpty
              ? SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.catching_pokemon,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет покемонов',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : SliverGrid(
            key: ValueKey('pokemon_grid_${widget.pokemonIds.length}'),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final pokemonId = displayPokemonIds[index];
                return GestureDetector(
                  onTap: () async {
                    final pokemon = await widget.viewModel.getPokemonById(pokemonId);
                    if (!mounted) return;
                    if (pokemon == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Не удалось загрузить покемона')),
                        );
                      }
                      return;
                    }
                    _showPokemonDetails(context, pokemon);
                  },
                  child: Hero(
                    tag: 'pokemon-$pokemonId',
                    child: SmallPokemonCard(
                      pokemonId: pokemonId,
                      viewModel: widget.viewModel,
                    ),
                  ),
                );
              },
              childCount: displayPokemonIds.length,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 24),
          sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
        ),
      ],
    );
  }
}
