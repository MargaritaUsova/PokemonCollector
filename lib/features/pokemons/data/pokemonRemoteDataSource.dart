import 'dart:math';
import 'package:dio/dio.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PokemonRemoteDataSource {
  final Dio dio;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  static const String baseUrl = 'https://pokeapi.co/api/v2';
  static const int maxPokemonId = 1000;
  static const int maxRetryAttempts = 5;
  static const int defaultPageSize = 20;

  PokemonRemoteDataSource({
    Dio? dio,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : dio = dio ?? Dio(),
        firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  Future<List<Pokemon>> getPokemons({
    int pageSize = defaultPageSize,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/pokemon',
        queryParameters: {'limit': pageSize, 'offset': offset},
      );

      if (response.statusCode != 200) {
        _logError('Failed to fetch pokemon list');
        return [];
      }

      final results = response.data['results'] as List;
      return await _loadPokemonBatch(results);
    } catch (e) {
      _logError('Error fetching pokemons: $e');
      return [];
    }
  }

  Future<Pokemon?> getPokemonById(String id) async {
    try {
      final response = await dio.get('$baseUrl/pokemon/$id');

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) return null;

      return Pokemon.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      return null;
    } catch (e) {
      _logError('Error fetching pokemon $id: $e');
      return null;
    }
  }

  Future<Pokemon?> getRandomPokemon() async {
    try {
      final listResponse = await dio.get(
        '$baseUrl/pokemon',
        queryParameters: {'limit': maxPokemonId, 'offset': 0},
      );

      if (listResponse.statusCode == 200) {
        final results = listResponse.data['results'] as List;
        if (results.isEmpty) return null;

        final randomPokemon = await _getRandomPokemonFromList(results);
        if (randomPokemon != null) {
          await _savePokemonToUserCollection(randomPokemon.id.toString());
          return randomPokemon;
        }
      }

      return await _getRandomPokemonWithRetry();
    } catch (e) {
      _logError('Error fetching random pokemon: $e');
      return await _getRandomPokemonWithRetry();
    }
  }

  Future<List<String>> getTypes() async {
    try {
      final response = await dio.get('$baseUrl/type');

      if (response.statusCode != 200) return [];

      final results = response.data['results'] as List;
      return results.map((t) => t['name'] as String).toList();
    } catch (e) {
      _logError('Error fetching types: $e');
      return [];
    }
  }

  Future<bool> hasUserPokemons() async {
    try {
      final user = auth.currentUser;
      if (user == null) return false;

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final pokemons = userDoc.data()?['pokemons'] as List<dynamic>?;
      return pokemons != null && pokemons.isNotEmpty;
    } catch (e) {
      _logError('Error checking user pokemons: $e');
      return false;
    }
  }

  Future<List<String>> getUserPokemonIds() async {
    try {
      final user = auth.currentUser;
      if (user == null) return [];

      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final pokemons = userDoc.data()?['pokemons'] as List<dynamic>?;
      if (pokemons == null || pokemons.isEmpty) return [];

      return pokemons.map((e) => e.toString()).toList();
    } catch (e) {
      _logError('Error getting user pokemon IDs: $e');
      return [];
    }
  }

  Future<Pokemon?> _getRandomPokemonWithRetry({
    int maxAttempts = maxRetryAttempts,
  }) async {
    final random = Random();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final randomId = random.nextInt(maxPokemonId) + 1;
        final pokemon = await _getPokemonByIdWithoutSaving(randomId.toString());

        if (pokemon != null) {
          await _savePokemonToUserCollection(randomId.toString());
          return pokemon;
        }
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          _logError('Failed to get random pokemon after $maxAttempts attempts');
        }
      }
    }

    return null;
  }

  Future<Pokemon?> _getPokemonByIdWithoutSaving(String id) async {
    try {
      final response = await dio.get('$baseUrl/pokemon/$id');
      if (response.statusCode != 200) return null;
      return Pokemon.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<Pokemon?> _getRandomPokemonFromList(List<dynamic> results) async {
    final random = Random();
    final randomIndex = random.nextInt(results.length);
    final randomPokemonUrl = results[randomIndex]['url'] as String;
    final pokemonId = _extractIdFromUrl(randomPokemonUrl);

    if (pokemonId != null) {
      return await _getPokemonByIdWithoutSaving(pokemonId.toString());
    }

    return null;
  }

  Future<List<Pokemon>> _loadPokemonBatch(List<dynamic> results) async {
    final futures = results.map((result) async {
      try {
        final pokemonUrl = result['url'] as String;
        final pokemonId = _extractIdFromUrl(pokemonUrl);

        if (pokemonId != null) {
          return await getPokemonById(pokemonId.toString());
        }
      } catch (e) {
        _logError('Error loading pokemon ${result['name']}: $e');
      }
      return null;
    }).toList();

    final resultsList = await Future.wait(futures, eagerError: false);
    return resultsList.whereType<Pokemon>().toList();
  }

  Future<void> _savePokemonToUserCollection(String pokemonId) async {
    try {
      final user = auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await firestore.collection('users').doc(user.uid).set({
        'pokemons': FieldValue.arrayUnion([pokemonId]),
      }, SetOptions(merge: true));
    } catch (e) {
      _logError('Error saving pokemon to collection: $e');
      rethrow;
    }
  }

  int? _extractIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      if (segments.isNotEmpty) {
        final id = int.tryParse(segments.last);
        if (id != null) return id;
      }

      final regex = RegExp(r'/(\d+)/?$');
      final match = regex.firstMatch(url);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    } catch (e) {
      _logError('Error extracting ID from URL: $e');
    }

    return null;
  }

  void _logError(String message) {
    print('Error [PokemonRemoteDataSource]: $message');
  }
}

