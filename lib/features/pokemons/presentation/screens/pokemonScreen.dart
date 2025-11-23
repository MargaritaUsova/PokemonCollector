import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokemon_collector/features/account/presentation/screens/accountScreen.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/PokemonStat.dart';

class PokemonCache {
  static final PokemonCache _instance = PokemonCache._internal();
  factory PokemonCache() => _instance;
  PokemonCache._internal();

  final Map<String, Pokemon> _cache = {};

  Pokemon? get(String id) => _cache[id];
  void set(String id, Pokemon pokemon) => _cache[id] = pokemon;
  bool contains(String id) => _cache.containsKey(id);
  void clear() => _cache.clear();
  int get size => _cache.length;
}

class PokemonScreen extends StatefulWidget {
  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late ConfettiController _confetti;
  bool _hasPokemons = false;
  bool _isCheckingPokemons = true;
  List<String> _userPokemonIds = [];
  bool _canTakeNewCard = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _checkUserPokemons();
    _checkDailyReward();
  }

  Future<void> _checkDailyReward() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isCheckingPokemons = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final pokemons = List<dynamic>.from(data?['pokemons'] ?? []);
      final lastTs = data?['lastCardReceived'] as Timestamp?;

      final now = DateTime.now();
      bool canTakeCard = lastTs == null;

      if (lastTs != null) {
        final diff = now.difference(lastTs.toDate()).inHours;
        canTakeCard = diff >= 24;
      }

      setState(() {
        _userPokemonIds = pokemons.map((e) => e.toString()).toList();
        _hasPokemons = _userPokemonIds.isNotEmpty;
        _canTakeNewCard = canTakeCard;
        _isCheckingPokemons = false;
      });
    } catch (e) {
      print('Error checking daily reward: $e');
      setState(() => _isCheckingPokemons = false);
    }
  }

  Future<void> _checkUserPokemons() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isCheckingPokemons = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final pokemons = userDoc.data()?['pokemons'] as List<dynamic>?;
        setState(() {
          _hasPokemons = pokemons != null && pokemons.isNotEmpty;
          _userPokemonIds = pokemons?.map((e) => e.toString()).toList() ?? [];
          _isCheckingPokemons = false;
        });
      } else {
        setState(() {
          _hasPokemons = false;
          _isCheckingPokemons = false;
        });
      }
    } catch (e) {
      print('Error checking user pokemons: $e');
      setState(() => _isCheckingPokemons = false);
    }
  }

  Future<void> _saveCardTimestamp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'lastCardReceived': Timestamp.now()});
    } catch (e) {
      print('Error saving card timestamp: $e');
    }
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AccountScreen()),
          ),
        ),
      ),
      body: _isCheckingPokemons
          ? Center(child: CircularProgressIndicator())
          : _hasPokemons
          ? _PokemonCollectionView(
        pokemonIds: _userPokemonIds,
        viewModel: viewModel,
        showBackCardFirst: _canTakeNewCard,
        breathController: _breathController,
        confetti: _confetti,
        onPokemonCaught: () {
          _saveCardTimestamp();
          _checkDailyReward();
        },
      )
          : _NewPlayerView(
        breathController: _breathController,
        confetti: _confetti,
        viewModel: viewModel,
        onPokemonCaught: () {
          _saveCardTimestamp();
          _checkDailyReward();
        },
      ),
    );
  }
}

class _NewPlayerView extends StatelessWidget {
  final AnimationController breathController;
  final ConfettiController confetti;
  final PokemonViewModel viewModel;
  final VoidCallback onPokemonCaught;

  const _NewPlayerView({
    required this.breathController,
    required this.confetti,
    required this.viewModel,
    required this.onPokemonCaught,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ConfettiOverlay(confetti: confetti),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FlipCard(
                breathController: breathController,
                imageUrl: viewModel.randomPokemonImageUrl,
                pokemon: viewModel.randomPokemon,
                isLoading: viewModel.isLoadingRandom,
                onTap: () {
                  viewModel.loadRandomPokemon();
                  Future.delayed(const Duration(milliseconds: 5500), onPokemonCaught);
                },
                confetti: confetti,
              ),
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
    );
  }
}

class _PokemonCollectionView extends StatelessWidget {
  final List<String> pokemonIds;
  final PokemonViewModel viewModel;
  final bool showBackCardFirst;
  final AnimationController? breathController;
  final ConfettiController? confetti;
  final VoidCallback? onPokemonCaught;

  const _PokemonCollectionView({
    required this.pokemonIds,
    required this.viewModel,
    this.showBackCardFirst = false,
    this.breathController,
    this.confetti,
    this.onPokemonCaught,
  });

  @override
  Widget build(BuildContext context) {
    final reversedIds = pokemonIds.reversed.toList();
    final itemCount = showBackCardFirst ? reversedIds.length + 1 : reversedIds.length;

    return Stack(
      children: [
        if (showBackCardFirst && confetti != null) _ConfettiOverlay(confetti: confetti!),
        GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (showBackCardFirst && index == 0) {
              return _SmallFlipCard(
                breathController: breathController!,
                confetti: confetti!,
                viewModel: viewModel,
                onPokemonCaught: onPokemonCaught!,
              );
            }

            final pokemonIndex = showBackCardFirst ? index - 1 : index;
            return _SmallPokemonCard(
              pokemonId: reversedIds[pokemonIndex],
              viewModel: viewModel,
            );
          },
        ),
      ],
    );
  }
}

class _SmallFlipCard extends StatefulWidget {
  final AnimationController breathController;
  final ConfettiController confetti;
  final PokemonViewModel viewModel;
  final VoidCallback onPokemonCaught;

  const _SmallFlipCard({
    required this.breathController,
    required this.confetti,
    required this.viewModel,
    required this.onPokemonCaught,
  });

  @override
  State<_SmallFlipCard> createState() => _SmallFlipCardState();
}

class _SmallFlipCardState extends State<_SmallFlipCard> with TickerProviderStateMixin {
  late Animation<double> _breathe;
  late AnimationController _spinController;
  late AnimationController _glowController;
  bool _isSpinning = false;
  bool _isRevealed = false;
  Pokemon? _revealedPokemon;
  final _cache = PokemonCache();

  @override
  void initState() {
    super.initState();
    _breathe = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: widget.breathController, curve: Curves.easeInOut),
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

  Future<void> _handleTap() async {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
      _isRevealed = false;
    });

    _spinController.forward(from: 0);
    widget.viewModel.loadRandomPokemon();

    await Future.delayed(const Duration(milliseconds: 5000));

    if (_isSpinning && widget.viewModel.randomPokemonImageUrl != null) {
      final newPokemon = widget.viewModel.randomPokemon;
      if (newPokemon != null && newPokemon.id != null) {
        _cache.set(newPokemon.id.toString(), newPokemon);
      }

      setState(() {
        _isSpinning = false;
        _isRevealed = true;
        _revealedPokemon = newPokemon;
      });
      widget.confetti.play();
      Future.delayed(Duration(milliseconds: 500), widget.onPokemonCaught);
    } else {
      setState(() => _isSpinning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _spinController, _glowController]),
      builder: (_, __) {
        final shouldBreathe = !_isSpinning && !_isRevealed;
        final scale = shouldBreathe ? _breathe.value : 1.0;
        final t = _spinController.value;
        final curvedValue = t * t;
        final spinAngle = _isSpinning ? curvedValue * 12 * 2 * pi : 0.0;
        final glowIntensity = _isRevealed ? _glowController.value : 0.0;
        final showFront = _isRevealed && !_isSpinning && _revealedPokemon != null;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(scale)
            ..rotateY(spinAngle),
          child: GestureDetector(
            onTap: _handleTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                  if (_isRevealed)
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5 * glowIntensity),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: showFront
                    ? _PokemonCardContent(pokemon: _revealedPokemon!)
                    : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset('assets/images/pokemonBack.png', fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SmallPokemonCard extends StatefulWidget {
  final String pokemonId;
  final PokemonViewModel viewModel;

  const _SmallPokemonCard({
    required this.pokemonId,
    required this.viewModel,
  });

  @override
  State<_SmallPokemonCard> createState() => _SmallPokemonCardState();
}

class _SmallPokemonCardState extends State<_SmallPokemonCard> {
  Pokemon? _pokemon;
  bool _isLoading = true;
  final _cache = PokemonCache();

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  Future<void> _loadPokemon() async {
    if (_cache.contains(widget.pokemonId)) {
      setState(() {
        _pokemon = _cache.get(widget.pokemonId);
        _isLoading = false;
      });
      return;
    }

    try {
      final pokemon = await widget.viewModel.getPokemonById(widget.pokemonId);
      if (pokemon != null) {
        _cache.set(widget.pokemonId, pokemon);
      }
      setState(() {
        _pokemon = pokemon;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pokemon: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showPokemonDetails() {
    if (_pokemon == null) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _PokemonDetailScreen(pokemon: _pokemon!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _LoadingCard();
    if (_pokemon == null) return _ErrorCard();

    return GestureDetector(
      onTap: _showPokemonDetails,
      child: _PokemonCardContent(pokemon: _pokemon!),
    );
  }
}

class _PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;

  const _PokemonDetailScreen({required this.pokemon});

  @override
  State<_PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<_PokemonDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hp = widget.pokemon.stats.isNotEmpty
        ? widget.pokemon.stats
        .firstWhere(
          (s) => s.name == 'hp',
      orElse: () => PokemonStat(baseStat: 0, effort: 0, name: 'hp'),
    )
        .baseStat
        .toString()
        : '0';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(_rotationAnimation.value),
                  child: Container(
                    width: 350,
                    height: 550,
                    margin: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFF3B0), Color(0xFFFFD56F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.shade700, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHeader(hp),
                        Expanded(child: _buildImage()),
                        _buildStats(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String hp) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              widget.pokemon.name.toUpperCase(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$hp HP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Image.network(
        widget.pokemon.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, size: 100),
      ),
    );
  }

  Widget _buildStats() {
    final type = widget.pokemon.types.isNotEmpty ? widget.pokemon.types.join(', ') : 'Unknown';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('Type', type),
          SizedBox(height: 8),
          _buildStatRow('Category', widget.pokemon.category),
          SizedBox(height: 8),
          _buildRarityRow(),
          SizedBox(height: 12),
          _buildAllStats(),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRarityRow() {
    return Row(
      children: [
        Text('Rarity: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getRarityColor(widget.pokemon.rarity),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.pokemon.rarity,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllStats() {
    if (widget.pokemon.stats.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stats:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        ...widget.pokemon.stats.map((stat) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(stat.name.toUpperCase(), style: TextStyle(fontSize: 14)),
              Text('${stat.baseStat}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        )),
      ],
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.purple;
      case 'rare':
        return Colors.blue;
      case 'uncommon':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class _PokemonCardContent extends StatelessWidget {
  final Pokemon pokemon;

  const _PokemonCardContent({required this.pokemon});

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return Colors.purple;
      case 'rare':
        return Colors.blue;
      case 'uncommon':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = pokemon.stats.isNotEmpty
        ? pokemon.stats
        .firstWhere((s) => s.name == 'hp',
        orElse: () => PokemonStat(baseStat: 0, effort: 0, name: 'hp'))
        .baseStat
        .toString()
        : '0';
    final type = pokemon.types.isNotEmpty ? pokemon.types.join(', ') : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFFFD56F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700, width: 3),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    pokemon.name.toUpperCase(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$hp HP',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                pokemon.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.catching_pokemon, size: 50, color: Colors.grey),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Type: $type',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text('Rarity: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRarityColor(pokemon.rarity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pokemon.rarity,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Center(child: Icon(Icons.error_outline, color: Colors.red, size: 40)),
    );
  }
}

class _ConfettiOverlay extends StatelessWidget {
  final ConfettiController confetti;

  const _ConfettiOverlay({required this.confetti});

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                confettiController: confetti,
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
    );
  }
}

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
      CurvedAnimation(parent: widget.breathController, curve: Curves.easeInOut),
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
      setState(() {
        _isSpinning = false;
        _isRevealed = true;
      });
      widget.confetti.play();
    } else {
      setState(() => _isSpinning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _spinController, _glowController]),
      builder: (_, __) {
        final shouldBreathe = !_isSpinning && !_isRevealed;
        final scale = shouldBreathe ? _breathe.value : 1.0;
        final t = _spinController.value;
        final curvedValue = t * t;
        final spinAngle = _isSpinning ? curvedValue * 12 * 2 * pi : 0.0;
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
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
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
                child: showFront && widget.imageUrl != null && widget.pokemon != null
                    ? _buildFrontCard()
                    : Image.asset('assets/images/pokemonBack.png', fit: BoxFit.cover),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFrontCard() {
    final hp = widget.pokemon.stats.isNotEmpty
        ? widget.pokemon.stats
        .firstWhere((s) => s.name == 'hp',
        orElse: () => PokemonStat(baseStat: 0, effort: 0, name: 'hp'))
        .baseStat
        .toString()
        : '0';
    final type = widget.pokemon.types.isNotEmpty ? widget.pokemon.types.join(', ') : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF3B0), Color(0xFFFFD56F)],
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
              padding: const EdgeInsets.only(top: 60, left: 8, right: 8, bottom: 90),
              child: Image.network(widget.imageUrl!, fit: BoxFit.contain),
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
                    widget.pokemon.name.toUpperCase(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('$hp HP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
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
                  Text('Type: $type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 6),
                  Text('Category: ${widget.pokemon.category}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
