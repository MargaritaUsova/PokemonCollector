import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/core/theme/app_theme.dart';
import '../viewmodels/friend_collection_viewmodel.dart';

class TradeRequestsScreen extends StatelessWidget {
  final String friendId;

  const TradeRequestsScreen({super.key, required this.friendId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.swap_horiz, size: 24),
              SizedBox(width: 8),
              Text('Запросы на обмен'),
            ],
          ),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.inbox), text: 'Входящие'),
              Tab(icon: Icon(Icons.send), text: 'Исходящие'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildIncomingRequests(currentUser?.uid, theme),
            _buildOutgoingRequests(currentUser?.uid, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequests(String? userId, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('status', isEqualTo: 'pending')
          .where('to', isEqualTo: userId)
          .where('from', isEqualTo: friendId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Нет входящих запросов',
            subtitle: 'Предложения обмена от друга появятся здесь',
            theme: theme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            return _TradeRequestTile(
              key: ValueKey(requests[index].id),
              tradeId: requests[index].id,
              fromUserId: data['from'],
              fromCard: data['fromCard'].toString(),
              toCard: data['toCard'].toString(),
              isIncoming: true,
            );
          },
        );
      },
    );
  }

  Widget _buildOutgoingRequests(String? userId, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('status', isEqualTo: 'pending')
          .where('from', isEqualTo: userId)
          .where('to', isEqualTo: friendId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            title: 'Нет исходящих запросов',
            subtitle: 'Ваши предложения обмена появятся здесь',
            theme: theme,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            return _TradeRequestTile(
              key: ValueKey(requests[index].id),
              tradeId: requests[index].id,
              fromUserId: data['from'],
              fromCard: data['fromCard'].toString(),
              toCard: data['toCard'].toString(),
              isIncoming: false,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: theme.colorScheme.outline),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeRequestTile extends StatefulWidget {
  final String tradeId;
  final String fromUserId;
  final String fromCard;
  final String toCard;
  final bool isIncoming;

  const _TradeRequestTile({
    Key? key,
    required this.tradeId,
    required this.fromUserId,
    required this.fromCard,
    required this.toCard,
    required this.isIncoming,
  }) : super(key: key);

  @override
  State<_TradeRequestTile> createState() => _TradeRequestTileState();
}

class _TradeRequestTileState extends State<_TradeRequestTile> {
  bool _isProcessing = false;

  String get _title {
    return widget.isIncoming
        ? 'Друг предлагает обмен'
        : 'Вы предлагаете обмен';
  }

  String get _fromLabel {
    return widget.isIncoming
        ? 'Друг предлагает:'
        : 'Вы отдаете:';
  }

  String get _toLabel {
    return widget.isIncoming
        ? 'За вашу карту:'
        : 'Вы получаете:';
  }

  Future<void> _acceptTrade() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final tradeDoc = await FirebaseFirestore.instance
          .collection('tradeRequests')
          .doc(widget.tradeId)
          .get();

      if (!tradeDoc.exists || tradeDoc.data()?['status'] != 'pending') {
        if (!mounted) return;
        _showMessage('Запрос уже обработан');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      final myRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      batch.update(myRef, {'pokemons': FieldValue.arrayRemove([widget.toCard])});
      batch.update(myRef, {'pokemons': FieldValue.arrayUnion([widget.fromCard])});

      final friendRef = FirebaseFirestore.instance.collection('users').doc(widget.fromUserId);
      batch.update(friendRef, {'pokemons': FieldValue.arrayRemove([widget.fromCard])});
      batch.update(friendRef, {'pokemons': FieldValue.arrayUnion([widget.toCard])});

      batch.update(
        FirebaseFirestore.instance.collection('tradeRequests').doc(widget.tradeId),
        {'status': 'completed', 'timestamp': Timestamp.now()},
      );

      await batch.commit();

      if (!mounted) return;
      _showMessage('Обмен успешно завершен!');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Ошибка обмена: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectTrade() async {
    try {
      await FirebaseFirestore.instance
          .collection('tradeRequests')
          .doc(widget.tradeId)
          .update({'status': 'rejected'});

      if (mounted) _showMessage('Запрос отклонен');
    } catch (e) {}
  }

  Future<void> _cancelTrade() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
        title: const Text('Отменить запрос?'),
        content: const Text('Вы уверены что хотите отменить этот запрос на обмен?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('tradeRequests')
          .doc(widget.tradeId)
          .delete();

      if (mounted) _showMessage('Запрос отменен');
    } catch (e) {
      if (mounted) _showMessage('Ошибка при отмене');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: message.contains('успешно') || message.contains('завершен')
            ? Colors.green
            : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FriendCollectionViewModel>();
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isIncoming ? Icons.inbox : Icons.send,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 14 : 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 12 : 16),
            isLandscape
                ? _buildLandscapeCards(viewModel, theme)
                : _buildPortraitCards(viewModel, theme),
            SizedBox(height: isLandscape ? 12 : 16),
            _buildActions(isLandscape),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitCards(FriendCollectionViewModel viewModel, ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildCardColumn(_fromLabel, widget.fromCard, viewModel, theme)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.swap_horiz, size: 32, color: theme.colorScheme.primary),
        ),
        Expanded(child: _buildCardColumn(_toLabel, widget.toCard, viewModel, theme)),
      ],
    );
  }

  Widget _buildLandscapeCards(FriendCollectionViewModel viewModel, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(_fromLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Expanded(child: SizedBox(height: 100, child: _TradeCardPreview(pokemonId: widget.fromCard, viewModel: viewModel))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Icon(Icons.swap_horiz, size: 24, color: theme.colorScheme.primary),
        ),
        Expanded(
          child: Row(
            children: [
              Text(_toLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Expanded(child: SizedBox(height: 100, child: _TradeCardPreview(pokemonId: widget.toCard, viewModel: viewModel))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardColumn(String label, String pokemonId, FriendCollectionViewModel viewModel, ThemeData theme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 140, child: _TradeCardPreview(pokemonId: pokemonId, viewModel: viewModel)),
      ],
    );
  }

  Widget _buildActions(bool isLandscape) {
    if (widget.isIncoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: Icon(Icons.close, size: isLandscape ? 18 : 20),
            label: Text(isLandscape ? 'Нет' : 'Отклонить'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: _isProcessing ? null : _rejectTrade,
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: _isProcessing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(Icons.check, size: isLandscape ? 18 : 20),
            label: Text(_isProcessing ? 'Обработка...' : (isLandscape ? 'Да' : 'Принять')),
            onPressed: _isProcessing ? null : _acceptTrade,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        icon: Icon(Icons.delete_outline, size: isLandscape ? 18 : 20),
        label: const Text('Отменить'),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        onPressed: _cancelTrade,
      ),
    );
  }
}

class _TradeCardPreview extends StatefulWidget {
  final String pokemonId;
  final FriendCollectionViewModel viewModel;

  const _TradeCardPreview({required this.pokemonId, required this.viewModel});

  @override
  State<_TradeCardPreview> createState() => _TradeCardPreviewState();
}

class _TradeCardPreviewState extends State<_TradeCardPreview> {
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
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
      );
    }

    if (_pokemon == null) {
      return Container(
        decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Icon(Icons.error, color: theme.colorScheme.error)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorderColor(context), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              _pokemon!.name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onPrimaryContainer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.network(
                _pokemon!.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, size: 40, color: theme.colorScheme.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
