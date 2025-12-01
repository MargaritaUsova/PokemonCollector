import 'package:flutter/material.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';

class FullscreenPokemonCard extends StatefulWidget {
  final Pokemon pokemon;
  final VoidCallback onClosed;

  const FullscreenPokemonCard({
    Key? key,
    required this.pokemon,
    required this.onClosed,
  }) : super(key: key);

  @override
  State<FullscreenPokemonCard> createState() => _FullscreenPokemonCardState();
}

class _FullscreenPokemonCardState extends State<FullscreenPokemonCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _showHint = true;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();

    // Скрываем подсказку через 4 секунды
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) setState(() => _showHint = false);
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
    Future.delayed(Duration(milliseconds: 200), widget.onClosed);
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Colors.orange;
      case 'water': return Colors.blue;
      case 'grass': return Colors.green;
      case 'electric': return Colors.yellow[700]!;
      case 'psychic': return Colors.purple;
      case 'ice': return Colors.cyan;
      case 'dragon': return Colors.indigo;
      case 'dark': return Colors.brown[700]!;
      case 'fairy': return Colors.pink;
      case 'normal': return Colors.grey[600]!;
      case 'fighting': return Colors.red[600]!;
      case 'flying': return Colors.lightBlue;
      case 'poison': return Colors.deepPurple;
      case 'ground': return Colors.brown[400]!;
      case 'rock': return Colors.grey[700]!;
      case 'bug': return Colors.lightGreen[600]!;
      case 'ghost': return Colors.deepPurple[900]!;
      case 'steel': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: _close,
        child: Stack(
          children: [
            // Фоновая градиентная волна
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.indigo.withOpacity(0.2),
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),

            // Главная карта покемона
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 340,
                  height: 480,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: Offset(-10, -10),
                      ),
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Заголовок
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (widget.pokemon.name ?? '').toUpperCase(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber[700],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.pokemon.rarity ?? 'Common',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Изображение покемона
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Image.network(
                            widget.pokemon.imageUrl ?? '',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.grey[300]!,
                                  Colors.grey[100]!,
                                ]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.catching_pokemon,
                                size: 120,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Типы
                      if (widget.pokemon.types != null && widget.pokemon.types!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: widget.pokemon.types!.map((type) => Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getTypeColor(type),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getTypeColor(type).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Кнопка закрытия
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: _close,
                    child: Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
            ),

            // Подсказка
            if (_showHint)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🎉 Поздравляем!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Нажми на карту чтобы добавить в коллекцию',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
