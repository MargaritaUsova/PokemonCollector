import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:provider/provider.dart';

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
  List<String> _friendPokemonIds = [];
  bool _isLoading = true;
  String? _selectedFriendCard;

  @override
  void initState() {
    super.initState();
    _loadFriendCollection();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFriendCollection();
  }

  Future<void> _loadFriendCollection() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendId)
          .get();

      if (!mounted) return;

      final data = doc.data();
      final pokemons = List<String>.from(data?['pokemons'] ?? []);

      setState(() {
        _friendPokemonIds = pokemons.reversed.toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading friend collection: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _proposeTradeDialog() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.friendId)
        .get();

    if (!myDoc.exists || !friendDoc.exists) return;

    final myPokemons = List<String>.from(myDoc.data()?['pokemons'] ?? []);
    final friendPokemons = List<String>.from(friendDoc.data()?['pokemons'] ?? []);

    if (_selectedFriendCard == null) return;

    if (!friendPokemons.contains(_selectedFriendCard)) {
      if (!mounted) return;
      _showMessage('Эта карточка больше не доступна у друга', isError: true);
      setState(() => _selectedFriendCard = null);
      return;
    }

    if (myPokemons.contains(_selectedFriendCard)) {
      if (!mounted) return;
      _showMessage('Эта карточка уже есть у вас!', isError: true);
      setState(() => _selectedFriendCard = null);
      return;
    }

    if (myPokemons.isEmpty) {
      if (!mounted) return;
      _showMessage('У вас нет карточек для обмена');
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _TradeSelectionDialog(
        myPokemonIds: myPokemons,
        friendCardId: _selectedFriendCard!,
        onConfirm: (myCardId) => _sendTradeRequest(myCardId, _selectedFriendCard!),
      ),
    );
  }

  Future<void> _sendTradeRequest(String myCardId, String friendCardId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friendId)
          .get();

      final myPokemons = List<String>.from(myDoc.data()?['pokemons'] ?? []);
      final friendPokemons = List<String>.from(friendDoc.data()?['pokemons'] ?? []);

      if (!myPokemons.contains(myCardId)) {
        if (!mounted) return;
        _showMessage('У вас больше нет этой карточки');
        return;
      }

      if (!friendPokemons.contains(friendCardId)) {
        if (!mounted) return;
        _showMessage('У друга больше нет этой карточки');
        return;
      }

      if (myCardId == friendCardId) {
        if (!mounted) return;
        _showMessage('Нельзя обменять одинаковые карточки');
        return;
      }

      await FirebaseFirestore.instance.collection('tradeRequests').add({
        'from': currentUser.uid,
        'to': widget.friendId,
        'fromCard': myCardId,
        'toCard': friendCardId,
        'status': 'pending',
        'timestamp': Timestamp.now(),
      });

      if (!mounted) return;

      setState(() => _selectedFriendCard = null);
      _showMessage('Предложение обмена отправлено!', isSuccess: true);
      _loadFriendCollection();
    } catch (e) {
      print('Error creating trade request: $e');
      if (!mounted) return;
      _showMessage('Ошибка: $e', isError: true);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Коллекция ${widget.friendName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _friendPokemonIds.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          if (_selectedFriendCard != null)
            _buildTradeActionBar(),
          Expanded(
            child: _buildPokemonGrid(viewModel),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TradeRequestsScreen(friendId: widget.friendId),
            ),
          );
        },
        icon: Icon(Icons.swap_horiz),
        label: Text('Обмены'),
        backgroundColor: Colors.amber.shade700,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.catching_pokemon, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'У пользователя пока нет карточек',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeActionBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Выбрана карточка для обмена',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.swap_horiz),
            label: Text('Предложить обмен'),
            onPressed: _proposeTradeDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => setState(() => _selectedFriendCard = null),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonGrid(PokemonViewModel viewModel) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _friendPokemonIds.length,
      itemBuilder: (context, index) {
        final pokemonId = _friendPokemonIds[index];
        final isSelected = pokemonId == _selectedFriendCard;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedFriendCard = isSelected ? null : pokemonId;
            });
          },
          child: Stack(
            children: [
              _FriendPokemonCard(
                pokemonId: pokemonId,
                viewModel: viewModel,
              ),
              if (isSelected) _buildSelectionOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade700, width: 4),
          color: Colors.amber.withOpacity(0.3),
        ),
        child: Center(
          child: Icon(
            Icons.check_circle,
            color: Colors.amber.shade700,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _FriendPokemonCard extends StatefulWidget {
  final String pokemonId;
  final PokemonViewModel viewModel;

  const _FriendPokemonCard({
    required this.pokemonId,
    required this.viewModel,
  });

  @override
  State<_FriendPokemonCard> createState() => _FriendPokemonCardState();
}

class _FriendPokemonCardState extends State<_FriendPokemonCard> {
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
      print('Error loading pokemon: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_pokemon == null) {
      return _buildErrorCard();
    }

    return _buildPokemonCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Icon(Icons.error)),
    );
  }

  Widget _buildPokemonCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFFFD56F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 3),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              _pokemon!.name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Image.network(_pokemon!.imageUrl, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeSelectionDialog extends StatefulWidget {
  final List<String> myPokemonIds;
  final String friendCardId;
  final Function(String) onConfirm;

  const _TradeSelectionDialog({
    required this.myPokemonIds,
    required this.friendCardId,
    required this.onConfirm,
  });

  @override
  State<_TradeSelectionDialog> createState() => _TradeSelectionDialogState();
}

class _TradeSelectionDialogState extends State<_TradeSelectionDialog> {
  String? _selectedMyCard;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonViewModel>();

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Выберите свою карточку'),
          SizedBox(height: 4),
          Text(
            'Ваших карточек: ${widget.myPokemonIds.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 400,
        child: widget.myPokemonIds.isEmpty
            ? Center(child: Text('У вас нет карточек'))
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.myPokemonIds.length,
          itemBuilder: (context, index) {
            final pokemonId = widget.myPokemonIds[index];
            final isSelected = pokemonId == _selectedMyCard;

            return GestureDetector(
              onTap: () => setState(() => _selectedMyCard = pokemonId),
              child: Stack(
                children: [
                  _MyPokemonCard(
                    pokemonId: pokemonId,
                    viewModel: viewModel,
                  ),
                  if (isSelected) _buildSelectionOverlay(),
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
        ElevatedButton(
          onPressed: _selectedMyCard == null
              ? null
              : () {
            widget.onConfirm(_selectedMyCard!);
            Navigator.pop(context);
          },
          child: Text('Предложить'),
        ),
      ],
    );
  }

  Widget _buildSelectionOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 3),
          color: Colors.green.withOpacity(0.3),
        ),
        child: Center(
          child: Icon(Icons.check_circle, color: Colors.green, size: 40),
        ),
      ),
    );
  }
}

class _MyPokemonCard extends StatefulWidget {
  final String pokemonId;
  final PokemonViewModel viewModel;

  const _MyPokemonCard({
    required this.pokemonId,
    required this.viewModel,
  });

  @override
  State<_MyPokemonCard> createState() => _MyPokemonCardState();
}

class _MyPokemonCardState extends State<_MyPokemonCard> {
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
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_pokemon == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Icon(Icons.error)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB0FFB0), Color(0xFF6FFF6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700, width: 3),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              _pokemon!.name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Image.network(_pokemon!.imageUrl, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class TradeRequestsScreen extends StatelessWidget {
  final String friendId;

  const TradeRequestsScreen({required this.friendId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Запросы на обмен'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Входящие'),
              Tab(text: 'Исходящие'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildIncomingRequests(currentUser?.uid),
            _buildOutgoingRequests(currentUser?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequests(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('status', isEqualTo: 'pending')
          .where('to', isEqualTo: userId)
          .where('from', isEqualTo: friendId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            message: 'Нет входящих запросов',
          );
        }

        return ListView.builder(
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

  Widget _buildOutgoingRequests(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('status', isEqualTo: 'pending')
          .where('from', isEqualTo: userId)
          .where('to', isEqualTo: friendId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            message: 'Нет исходящих запросов',
          );
        }

        return ListView.builder(
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

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600])),
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
        {'status': 'completed'},
      );

      await batch.commit();

      if (!mounted) return;
      _showMessage('Обмен завершен!', isSuccess: true);
    } catch (e) {
      print('Error accepting trade: $e');
      if (!mounted) return;
      _showMessage('Ошибка: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectTrade() async {
    try {
      await FirebaseFirestore.instance
          .collection('tradeRequests')
          .doc(widget.tradeId)
          .update({'status': 'rejected'});

      if (!mounted) return;
      _showMessage('Запрос отклонен');
    } catch (e) {
      print('Error rejecting trade: $e');
    }
  }

  Future<void> _cancelTrade() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Отменить запрос?'),
        content: Text('Вы уверены что хотите отменить этот запрос на обмен?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Да, отменить'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

      if (!mounted) return;
      _showMessage('Запрос отменен');
    } catch (e) {
      print('Error canceling trade: $e');
      if (!mounted) return;
      _showMessage('Ошибка при отмене', isError: true);
    }
  }

  void _showMessage(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
            ? Colors.red
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonViewModel>();

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isIncoming ? 'Предложение обмена' : 'Ваше предложение',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCardColumn('Предлагают:', widget.fromCard, viewModel),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.swap_horiz, size: 32, color: Colors.amber.shade700),
                ),
                Expanded(
                  child: _buildCardColumn('За:', widget.toCard, viewModel),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (widget.isIncoming)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.close, color: Colors.red),
                    label: Text('Отклонить'),
                    onPressed: _isProcessing ? null : _rejectTrade,
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: _isProcessing
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(Icons.check),
                    label: Text(_isProcessing ? 'Обмен...' : 'Принять'),
                    onPressed: _isProcessing ? null : _acceptTrade,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Отменить'),
                  onPressed: _cancelTrade,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardColumn(String label, String pokemonId, PokemonViewModel viewModel) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12)),
        SizedBox(height: 4),
        SizedBox(
          height: 120,
          child: _TradeCardPreview(
            pokemonId: pokemonId,
            viewModel: viewModel,
          ),
        ),
      ],
    );
  }
}

class _TradeCardPreview extends StatefulWidget {
  final String pokemonId;
  final PokemonViewModel viewModel;

  const _TradeCardPreview({
    required this.pokemonId,
    required this.viewModel,
  });

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
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_pokemon == null) {
      return Center(child: Icon(Icons.error));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFFFD56F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _pokemon!.name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Image.network(_pokemon!.imageUrl, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
