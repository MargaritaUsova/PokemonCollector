import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';

class FullscreenCardReveal extends StatefulWidget {
  final Pokemon pokemon;
  final ConfettiController confetti;
  final Function(int pokemonId) onComplete;

  const FullscreenCardReveal({
    Key? key,
    required this.pokemon,
    required this.confetti,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<FullscreenCardReveal> createState() => _FullscreenCardRevealState();
}

class _FullscreenCardRevealState extends State<FullscreenCardReveal>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _glowController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _bounceAnimation = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _bounceController.forward();
    widget.confetti.play();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onComplete(widget.pokemon.id ?? 0);
    });
  }

  Color _getPrimaryColor() {
    final type = widget.pokemon.types?.firstOrNull?.toLowerCase() ?? 'normal';
    return _getTypeColor(type);
  }

  static const Map<String, Color> _typeColors = {
    'fire': Color(0xFFF87171),
    'water': Color(0xFF60A5FA),
    'grass': Color(0xFF86EFAC),
    'electric': Color(0xFFFCD34D),
    'psychic': Color(0xFFEC4899),
    'ice': Color(0xFFBAF5FF),
    'dragon': Color(0xFF8B5CF6),
    'dark': Color(0xFF92400E),
    'fairy': Color(0xFFFACBDE),
    'normal': Color(0xFFD1D5DB),
    'fighting': Color(0xFFFB7185),
    'flying': Color(0xFF93C5FD),
    'poison': Color(0xFFCA8AFF),
    'ground': Color(0xFFCA8A04),
    'rock': Color(0xFFCA8A04),
    'bug': Color(0xFFCAFC8A),
    'ghost': Color(0xFFAC7BFF),
    'steel': Color(0xFF9CA3AF),
  };

  Color _getTypeColor(String type) => _typeColors[type.toLowerCase()] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _getPrimaryColor();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: widget.confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 15,
              gravity: 0.08,
              colors: [
                Colors.white,
                theme.colorScheme.primary,
                Colors.yellow.shade300,
                Colors.pink.shade300,
              ],
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_bounceAnimation, _glowAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: Hero(
                      tag: 'pokemon_${widget.pokemon.id}',
                      child: _UnifiedPokemonCard(
                        pokemon: widget.pokemon,
                        primaryColor: primaryColor,
                        glowScale: _glowAnimation.value,
                        theme: theme,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: _UnifiedCloseButton(
                  onPressed: _handleTap,
                  theme: theme,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedPokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final Color primaryColor;
  final double glowScale;
  final ThemeData theme;

  const _UnifiedPokemonCard({
    required this.pokemon,
    required this.primaryColor,
    required this.glowScale,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 480,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2 * glowScale),
            blurRadius: 30,
            spreadRadius: 5 * glowScale,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            _UnifiedHeader(
              pokemon: pokemon,
              primaryColor: primaryColor,
              theme: theme,
            ),
            Expanded(child: _UnifiedImage(pokemon: pokemon)),
            if (pokemon.types?.isNotEmpty == true)
              _UnifiedTypes(types: pokemon.types!, primaryColor: primaryColor),
          ],
        ),
      ),
    );
  }
}

class _UnifiedHeader extends StatelessWidget {
  final Pokemon pokemon;
  final Color primaryColor;
  final ThemeData theme;

  const _UnifiedHeader({
    required this.pokemon,
    required this.primaryColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hp = _getHPValue(pokemon);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.12),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              (pokemon.name ?? 'Unknown').toUpperCase(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 1),
            ),
            child: Text(
              '$hp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHPValue(Pokemon pokemon) {
    if (pokemon.stats == null || pokemon.stats!.isEmpty) return '50';
    try {
      final hpStat = pokemon.stats!.firstWhere(
            (s) => (s.name ?? '').toLowerCase() == 'hp',
        orElse: () => pokemon.stats!.first,
      );
      return (hpStat.baseStat ?? 50).toString();
    } catch (e) {
      return '50';
    }
  }
}

class _UnifiedImage extends StatelessWidget {
  final Pokemon pokemon;

  const _UnifiedImage({required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          pokemon.imageUrl ?? '',
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey.shade100,
            child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _UnifiedTypes extends StatelessWidget {
  final List<String> types;
  final Color primaryColor;

  const _UnifiedTypes({required this.types, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: types.take(2).map((type) {
          final color = _FullscreenCardRevealState._typeColors[type.toLowerCase()] ?? Colors.grey;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UnifiedCloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final ThemeData theme;

  const _UnifiedCloseButton({
    required this.onPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close_rounded,
          color: theme.colorScheme.primary,
          size: 24,
        ),
      ),
    );
  }
}
