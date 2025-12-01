import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/friend_collection_viewmodel.dart';
import 'friend_pokemon_card.dart';

class TradeSelectionDialog extends StatefulWidget {
  final List<String> myPokemonIds;
  final String friendCardId;
  final Function(String) onConfirm;

  const TradeSelectionDialog({
    required this.myPokemonIds,
    required this.friendCardId,
    required this.onConfirm,
  });

  @override
  State<TradeSelectionDialog> createState() => _TradeSelectionDialogState();
}

class _TradeSelectionDialogState extends State<TradeSelectionDialog> {
  String? _selectedMyCard;

  void _toggleSelection(String pokemonId) {
    setState(() {
      // Если уже выбрана эта карточка - снимаем выбор
      if (_selectedMyCard == pokemonId) {
        _selectedMyCard = null;
      } else {
        // Иначе выбираем новую
        _selectedMyCard = pokemonId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<FriendCollectionViewModel>();
    final theme = Theme.of(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final crossAxisCount = isLandscape ? 3 : 2;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: theme.colorScheme.primary, size: 24),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Выберите карточку',
                  style: TextStyle(fontSize: isLandscape ? 18 : 20),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Ваших карточек: ${widget.myPokemonIds.length}',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.normal,
            ),
          ),
          if (_selectedMyCard != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Нажмите еще раз для отмены',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: isLandscape ? 300 : 400,
        child: widget.myPokemonIds.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.outline),
              SizedBox(height: 16),
              Text(
                'У вас нет карточек',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        )
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: widget.myPokemonIds.length,
          itemBuilder: (context, index) {
            final pokemonId = widget.myPokemonIds[index];
            final isSelected = pokemonId == _selectedMyCard;

            return GestureDetector(
              onTap: () => _toggleSelection(pokemonId),
              child: Stack(
                children: [
                  FriendPokemonCard(
                    pokemonId: pokemonId,
                    viewModel: viewModel,
                    onTap: () => _toggleSelection(pokemonId),
                  ),
                  if (isSelected) _buildSelectionOverlay(theme),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton.icon(
          icon: Icon(Icons.check),
          label: Text('Предложить'),
          onPressed: _selectedMyCard == null
              ? null
              : () {
            widget.onConfirm(_selectedMyCard!);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildSelectionOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 3),
          color: Colors.green.withOpacity(0.2),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.check, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
