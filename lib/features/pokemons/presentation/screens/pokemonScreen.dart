import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokemon_collector/features/account/presentation/screens/accountScreen.dart';
import 'package:pokemon_collector/features/pokemons/presentation/viewModels/pokemonScreenViewModel.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/new_player_view.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/pokemon_collection_view.dart';
import 'package:pokemon_collector/features/pokemons/presentation/widgets/small_flip_card.dart';

class PokemonScreen extends StatefulWidget {
  @override
  _PokemonScreenState createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> with TickerProviderStateMixin {
  late ConfettiController confetti;
  bool _isSaving = false;
  bool _isLoading = true;

  List<String> _pokemonIds = [];
  Timestamp? _lastTs;
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    confetti = ConfettiController(duration: const Duration(seconds: 3));
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Инициализируем из Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _pokemonIds = List<String>.from(data['pokemons'] ?? []);
          _lastTs = data['lastCardReceived'] as Timestamp?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }

      // Слушаем изменения Firestore
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data() as Map<String, dynamic>;
          if (!_isSaving) {
            setState(() {
              _pokemonIds = List<String>.from(data['pokemons'] ?? []);
              _lastTs = data['lastCardReceived'] as Timestamp?;
            });
          }
        }
      });
    }
  }

  bool _calculateCanTakeNewCard(Timestamp? lastTs) {
    final now = DateTime.now();
    if (lastTs == null) return true;

    final lastCardTime = lastTs.toDate();
    final roundedLastTime = DateTime(
      lastCardTime.year, lastCardTime.month, lastCardTime.day,
      lastCardTime.hour, 0, 0, 0, 0,
    );
    final nextCardTime = roundedLastTime.add(const Duration(hours: 24));
    return now.isAfter(nextCardTime);
  }

  Future<void> _savePokemonAndTimestamp(int pokemonId) async {
    if (_isSaving) return;


    setState(() {
      _isSaving = true;
      _pokemonIds.insert(0, pokemonId.toString());
      final preciseTime = DateTime.now().toUtc().subtract(
          Duration(milliseconds: DateTime.now().millisecond)
      );
      _lastTs = Timestamp.fromDate(preciseTime);
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final serverTime = DateTime.now().toUtc().subtract(
          Duration(milliseconds: DateTime.now().millisecond)
      );

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final currentPokemons = List<String>.from(doc.data()?['pokemons'] ?? []);

        if (!currentPokemons.contains(pokemonId.toString())) {
          currentPokemons.insert(0, pokemonId.toString());
          transaction.set(docRef, {
            'pokemons': currentPokemons,
            'lastCardReceived': Timestamp.fromDate(serverTime),
          }, SetOptions(merge: true));
        }
      });

    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _pokemonIds.remove(pokemonId.toString());
          _lastTs = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PokemonViewModel>();
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.catching_pokemon, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Необходима авторизация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Pokemon Cards')),
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    final hasPokemons = _pokemonIds.isNotEmpty;
    final canTakeNewCard = _calculateCanTakeNewCard(_lastTs) && !_isSaving;

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_rounded, color: theme.colorScheme.primary, size: 24),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountScreen())),
        ),
        title: Text('Pokemon Cards', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: hasPokemons
          ? PokemonCollectionView(
        pokemonIds: _pokemonIds,
        viewModel: viewModel,
        confetti: confetti,
        canTakeNewCard: canTakeNewCard,
        nextCardTime: _lastTs != null ? _lastTs!.toDate().add(const Duration(hours: 24)) : null,
        onPokemonCaught: _savePokemonAndTimestamp,
      )
          : NewPlayerView(
        confetti: confetti,
        viewModel: viewModel,
        canTakeNewCard: canTakeNewCard,
        onPokemonCaught: _savePokemonAndTimestamp,
      ),
    );
  }
}
