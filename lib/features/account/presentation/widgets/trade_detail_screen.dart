import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class TradeDetailScreen extends StatelessWidget {
  final String fromUserId;
  final String toUserId;
  final String fromCard;
  final String toCard;
  final DateTime? timestamp;
  final String currentUserId;
  final String? tradeId;

  const TradeDetailScreen({
    required this.fromUserId,
    required this.toUserId,
    required this.fromCard,
    required this.toCard,
    required this.timestamp,
    required this.currentUserId,
    this.tradeId,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}.${date.month}.${date.year} в ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<String> _getTradeStatus() async {
    if (tradeId == null) return 'completed';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('tradeRequests')
          .doc(tradeId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['status'] ?? 'completed';
      }
    } catch (e) {
      print('Error getting trade status: $e');
    }

    return 'completed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wasIncoming = toUserId == currentUserId;
    final otherUserId = wasIncoming ? fromUserId : toUserId;
    final myCard = wasIncoming ? toCard : fromCard;
    final theirCard = wasIncoming ? fromCard : toCard;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.swap_horiz, size: 24),
            SizedBox(width: 8),
            Flexible(child: Text('Детали обмена')),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, otherUserId, wasIncoming, theme),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTradeSection(
                      context,
                      'Вы отдали',
                      myCard,
                      Colors.red,
                      theme,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.swap_horiz, size: 32, color: theme.colorScheme.primary),
                  ),
                  Expanded(
                    child: _buildTradeSection(
                      context,
                      'Вы получили',
                      theirCard,
                      Colors.green,
                      theme,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String otherUserId, bool wasIncoming, ThemeData theme) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['displayName'] ?? 'Unknown';
        final photoURL = userData?['photoURL'];

        return FutureBuilder<String>(
          future: _getTradeStatus(),
          builder: (context, statusSnapshot) {
            final status = statusSnapshot.data ?? 'completed';
            final isPending = status == 'pending';
            final isCompleted = status == 'completed';
            final isRejected = status == 'rejected';

            Color statusColor = Colors.green;
            IconData statusIcon = Icons.check_circle;
            String statusText = 'Завершен';

            if (isPending) {
              statusColor = Colors.orange;
              statusIcon = Icons.schedule;
              statusText = 'В ожидании';
            } else if (isRejected) {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              statusText = 'Отклонен';
            }

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.brightness == Brightness.dark
                      ? [Color(0xFF1E3A2F), Color(0xFF2D5F2D)]
                      : [Color(0xFFB0FFB0), Color(0xFF6FFF6F)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                    child: photoURL == null ? Icon(Icons.person, size: 40) : null,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Обмен с $userName',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatDate(timestamp),
                    style: TextStyle(
                      color: theme.brightness == Brightness.dark ? Colors.white60 : Colors.black45,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTradeSection(
      BuildContext context,
      String title,
      String pokemonId,
      Color accentColor,
      ThemeData theme,
      ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        SizedBox(height: 12),
        _PokemonTradeCard(pokemonId: pokemonId),
      ],
    );
  }
}

class _PokemonTradeCard extends StatelessWidget {
  final String pokemonId;

  const _PokemonTradeCard({required this.pokemonId});

  int _getStatValue(dynamic pokemon, String statName) {
    if (pokemon == null || pokemon.stats == null) return 0;

    try {
      final matchingStats = pokemon.stats.where(
            (s) => (s.name ?? '').toLowerCase() == statName.toLowerCase(),
      );

      if (matchingStats.isNotEmpty) {
        return matchingStats.first.baseStat ?? 0;
      }
    } catch (e) {
      print('Error getting stat: $e');
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<PokemonViewModel>();
    final theme = Theme.of(context);

    return FutureBuilder(
      future: viewModel.getPokemonById(pokemonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(theme);
        }

        if (!snapshot.hasData || snapshot.hasError || snapshot.data == null) {
          return _buildErrorCard(theme, pokemonId);
        }

        final pokemon = snapshot.data;
        if (pokemon == null) return _buildErrorCard(theme, pokemonId);

        final hp = _getStatValue(pokemon, 'hp');
        final attack = _getStatValue(pokemon, 'attack');
        final defense = _getStatValue(pokemon, 'defense');

        return GestureDetector(
          onTap: () => _showPokemonDetails(context, pokemon),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient(context),
              borderRadius: BorderRadius.circular(16),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                  ),
                  child: Text(
                    (pokemon.name ?? 'Unknown').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Image.network(
                    pokemon.imageUrl ?? '',
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.catching_pokemon,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip('HP', hp.toString(), Colors.red, theme),
                      _buildStatChip('ATK', attack.toString(), Colors.orange, theme),
                      _buildStatChip('DEF', defense.toString(), Colors.blue, theme),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String pokemonId) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: theme.colorScheme.error, size: 48),
            SizedBox(height: 8),
            Text(
              'Покемон не найден',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
            Text(
              'ID: $pokemonId',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onErrorContainer.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPokemonDetails(BuildContext context, dynamic pokemon) {
    if (pokemon == null) return;

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
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                value.toString(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4),
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
      case 'ground':
        return Colors.brown.shade300;
      case 'rock':
        return Colors.brown.shade700;
      case 'bug':
        return Colors.lightGreen;
      case 'ghost':
        return Colors.deepPurple.shade900;
      case 'steel':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}
