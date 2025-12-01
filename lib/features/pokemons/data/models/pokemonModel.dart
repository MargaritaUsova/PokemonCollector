import 'package:pokemon_collector/features/pokemons/data/models/pokemonAbility.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonAttacks.dart';

import 'PokemonStat.dart';

class Pokemon {
  final int id;
  final String name;
  final int height;
  final int weight;
  final List<String> types;
  final List<PokemonAbility> abilities;
  final List<PokemonMove> moves;
  final Map<String, dynamic> sprites;
  final List<PokemonStat> stats;
  final String imageUrl;
  final String category;
  final String rarity;

  Pokemon({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.types,
    required this.abilities,
    required this.moves,
    required this.sprites,
    required this.stats,
    required this.imageUrl,
    required this.category,
    required this.rarity,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    try {
      final sprites = Map<String, dynamic>.from(json['sprites'] ?? {});

      String imageUrl = '';
      try {
        final other = sprites['other'] as Map<String, dynamic>?;
        if (other != null) {
          final officialArtwork = other['official-artwork'] as Map<String, dynamic>?;
          if (officialArtwork != null && officialArtwork['front_default'] != null) {
            imageUrl = officialArtwork['front_default'] as String;
          }
        }
        if (imageUrl.isEmpty && sprites['front_default'] != null) {
          imageUrl = sprites['front_default'] as String;
        }
      } catch (e) {
        print('Error parsing image URL: $e');
      }

      final typesList = (json['types'] as List? ?? [])
          .map((t) {
            try {
              return (t['type']?['name'] ?? '') as String;
            } catch (e) {
              return '';
            }
          })
          .where((t) => t.isNotEmpty)
          .toList();
      final category = typesList.isNotEmpty 
          ? (typesList[0].length > 1 
              ? typesList[0].substring(0, 1).toUpperCase() + typesList[0].substring(1)
              : typesList[0].toUpperCase())
          : 'Unknown';

      final baseExperience = json['base_experience'] as int? ?? 0;
      String rarity;
      if (baseExperience >= 300) {
        rarity = 'Legendary';
      } else if (baseExperience >= 200) {
        rarity = 'Rare';
      } else if (baseExperience >= 100) {
        rarity = 'Uncommon';
      } else {
        rarity = 'Common';
      }
      
      return Pokemon(
          id: json['id'] as int? ?? 0,
          name: (json['name'] as String?) ?? 'Unknown',
          height: json['height'] as int? ?? 0,
          weight: json['weight'] as int? ?? 0,
          types: typesList,
          abilities: (json['abilities'] as List? ?? [])
              .map((a) {
                try {
                  return PokemonAbility.fromJson(a as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing ability: $e');
                  return null;
                }
              })
              .whereType<PokemonAbility>()
              .toList(),
          moves: (json['moves'] as List? ?? [])
              .map((m) {
                try {
                  return PokemonMove.fromJson(m as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing move: $e');
                  return null;
                }
              })
              .whereType<PokemonMove>()
              .toList(),
          sprites: sprites,
          stats: (json['stats'] as List? ?? [])
              .map((s) {
                try {
                  return PokemonStat.fromJson(s as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing stat: $e');
                  return null;
                }
              })
              .whereType<PokemonStat>()
              .toList(),
          imageUrl: imageUrl,
          category: category,
          rarity: rarity
      );
    } catch (e, stackTrace) {
      print('Error parsing Pokemon from JSON: $e');
      print('Stack trace: $stackTrace');
      print('JSON keys: ${json.keys.toList()}');
      rethrow;
    }
  }
}

