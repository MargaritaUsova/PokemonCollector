import 'dart:math';
import 'package:dio/dio.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonAbility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokemon_collector/features/pokemons/data/models/PokemonStat.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PokemonRemoteDataSource {
  final Dio dio;
  static const String baseUrl = 'https://pokeapi.co/api/v2';

  PokemonRemoteDataSource({Dio? dio}) : dio = dio ?? Dio();

  /// Получить список покемонов
  Future<List<Pokemon>> getPokemons({int pageSize = 20, int offset = 0}) async {
    try {
      // Сначала получаем список покемонов
      final response = await dio.get(
        '$baseUrl/pokemon',
        queryParameters: {'limit': pageSize, 'offset': offset},
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        final pokemons = <Pokemon>[];

        final futures = results.map((result) async {
          try {
            final pokemonUrl = result['url'] as String;
            final pokemonId = _extractIdFromUrl(pokemonUrl);
            if (pokemonId != null) {
              return await getPokemonById(pokemonId.toString());
            }
          } catch (e) {
            print('Error loading pokemon ${result['name']}: $e');
          }
          return null;
        }).toList();

        final resultsList = await Future.wait(futures, eagerError: false);
        pokemons.addAll(resultsList.whereType<Pokemon>());

        return pokemons;
      }
      print('Failed to fetch pokemon list: status code ${response.statusCode}');
      return [];
    } catch (e, stackTrace) {
      print('Error fetching pokemons: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Получить одного покемона по ID
  Future<Pokemon?> getPokemonById(String id) async {
    try {
      final response = await dio.get('$baseUrl/pokemon/$id');

      if (response.statusCode == 200) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception('User not logged in');
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'pokemons': FieldValue.arrayUnion([id]),
          }, SetOptions(merge: true));

          return Pokemon.fromJson(response.data);
        } catch (e, stackTrace) {
          print('Error parsing pokemon $id: $e');
          print('Stack trace: $stackTrace');
          return null;
        }
      }
      if (response.statusCode == 404) {
        return null;
      }
      print('Failed to fetch pokemon $id: status code ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      print('Error fetching pokemon by id $id: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      print('Error fetching pokemon by id $id: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Получить случайного покемона
  Future<Pokemon?> getRandomPokemon() async {
    try {
      final listResponse = await dio.get(
        '$baseUrl/pokemon',
        queryParameters: {'limit': 1000, 'offset': 0},
      );
      
      if (listResponse.statusCode == 200) {
        final results = listResponse.data['results'] as List;
        if (results.isEmpty) {
          return null;
        }
        
        final random = Random();
        final randomIndex = random.nextInt(results.length);
        final randomPokemonUrl = results[randomIndex]['url'] as String;
        
        final pokemonId = _extractIdFromUrl(randomPokemonUrl);
        if (pokemonId != null) {
          return await getPokemonById(pokemonId.toString());
        }
      }
      
      return await _getRandomPokemonWithRetry();
    } catch (e, stackTrace) {
      print('Error fetching random pokemon: $e');
      print('Stack trace: $stackTrace');
      return await _getRandomPokemonWithRetry();
    }
  }

  Future<Pokemon?> _getRandomPokemonWithRetry({int maxAttempts = 5}) async {
    final random = Random();
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        final randomId = random.nextInt(1000) + 1;
        final pokemon = await getPokemonById(randomId.toString());
        
        if (pokemon != null) {
          return pokemon;
        }
        
        attempts++;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          print('Failed to get random pokemon after $maxAttempts attempts');
          return null;
        }
      }
    }
    
    return null;
  }

  /// Получить типы покемонов
  Future<List<String>> getTypes() async {
    try {
      final response = await dio.get('$baseUrl/type');

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results.map((t) => t['name'] as String).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching types: $e');
      return [];
    }
  }

  int? _extractIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        final idString = segments.last;
        final id = int.tryParse(idString);
        if (id != null) {
          return id;
        }
      }
      final regex = RegExp(r'/(\d+)/?$');
      final match = regex.firstMatch(url);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    } catch (e) {
      print('Error extracting ID from URL: $e');
    }
    return null;
  }
}
