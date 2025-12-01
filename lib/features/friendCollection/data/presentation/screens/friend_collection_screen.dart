import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokemon_collector/core/utils/responsive.dart';
import 'package:provider/provider.dart';
import '../viewmodels/friend_collection_viewmodel.dart';
import '../widgets/friend_pokemon_card.dart';
import '../widgets/trade_selection_dialog.dart';
import 'trade_requests_screen.dart';

class FriendCollectionScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const FriendCollectionScreen({
    required this.friendId,
    required this.friendName,
  });

  @override
  _FriendCollectionScreenState createState() => _FriendCollectionScreenState();
}

class _FriendCollectionScreenState extends State<FriendCollectionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<FriendCollectionViewModel>().loadFriendCollection(widget.friendId);
      }
    });
  }

  Future<void> _proposeTradeDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final viewModel = context.read<FriendCollectionViewModel>();
    await viewModel.loadMyCollection(currentUser.uid);

    if (!mounted) return;

    if (viewModel.selectedFriendCard == null) return;

    if (viewModel.myPokemonIds.isEmpty) {
      _showMessage('У вас нет карточек для обмена');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TradeSelectionDialog(
        myPokemonIds: viewModel.myPokemonIds,
        friendCardId: viewModel.selectedFriendCard!,
        onConfirm: (myCardId) => _sendTradeRequest(myCardId, viewModel.selectedFriendCard!),
      ),
    );
  }

  Future<void> _sendTradeRequest(String myCardId, String friendCardId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final viewModel = context.read<FriendCollectionViewModel>();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    try {
      await viewModel.sendTradeRequest(
        currentUser.uid,
        widget.friendId,
        myCardId,
        friendCardId,
      );

      if (!mounted) return;

      Navigator.pop(context);

      await viewModel.loadFriendCollection(widget.friendId);

      // ← Очищаем выбор
      if (mounted) {
        viewModel.selectCard(null);
      }

    } catch (e) {
      if (!mounted) return;

      // ← Закрываем лоадер при ошибке
      Navigator.pop(context);

      _showMessage('Ошибка при отправке запроса: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
            ? Colors.orange
            : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FriendCollectionViewModel>();
    final theme = Theme.of(context);

    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage(viewModel.errorMessage!, isError: true);
        viewModel.clearMessages();
      });
    }
    if (viewModel.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage(viewModel.successMessage!, isSuccess: true);
        viewModel.clearMessages();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.catching_pokemon, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Коллекция ${widget.friendName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.swap_horiz),
            tooltip: 'Запросы на обмен',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TradeRequestsScreen(friendId: widget.friendId),
                ),
              );
            },
          ),
        ],
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : viewModel.friendPokemonIds.isEmpty
          ? _buildEmptyState(theme)
          : Column(
        children: [
          if (viewModel.selectedFriendCard != null) _buildTradeActionBar(theme),
          Expanded(child: _buildPokemonGrid(viewModel, theme)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.catching_pokemon, size: 100, color: theme.colorScheme.outline),
          SizedBox(height: 24),
          Text(
            'У пользователя пока нет карточек',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Карточки появятся здесь после получения',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeActionBar(ThemeData theme) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.all(isLandscape ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary, size: isLandscape ? 20 : 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Выбрана карточка для обмена',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isLandscape ? 13 : 14,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.swap_horiz, size: isLandscape ? 18 : 20),
            label: Text(isLandscape ? 'Обмен' : 'Обменять'),
            onPressed: _proposeTradeDialog,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 12 : 16,
                vertical: isLandscape ? 8 : 12,
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, size: isLandscape ? 20 : 24),
            onPressed: () {
              context.read<FriendCollectionViewModel>().selectCard(null);
            },
            tooltip: 'Отменить выбор',
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonGrid(FriendCollectionViewModel viewModel, ThemeData theme) {
    final crossAxisCount = Responsive.getCrossAxisCount(context);
    final aspectRatio = Responsive.getCardAspectRatio(context);

    return GridView.builder(
      padding: Responsive.getScreenPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: viewModel.friendPokemonIds.length,
      itemBuilder: (context, index) {
        final pokemonId = viewModel.friendPokemonIds[index];
        final isSelected = pokemonId == viewModel.selectedFriendCard;

        return GestureDetector(
          onTap: () {
            viewModel.selectCard(isSelected ? null : pokemonId);
          },
          child: Stack(
            children: [
              FriendPokemonCard(
                pokemonId: pokemonId,
                viewModel: viewModel,
                onTap: () {
                  viewModel.selectCard(isSelected ? null : pokemonId);
                },
              ),
              if (isSelected) _buildSelectionOverlay(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary, width: 4),
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.check,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
