import 'package:pokemon_collector/features/pokemons/data/models/pokemonAbility.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonAttacks.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pokemonModel.g.dart';

@JsonSerializable()
class Pokemon {
  // Unique identifier for the object.
  final String id;
  // The name of the card.
  final String name;
  // The supertype of the card, such as Pokémon, Energy, or Trainer.
  final String supertype;
  // A list of subtypes, such as Basic, EX, Mega, Rapid Strike, etc.
  final List<String> subtypesList;
  // The hit points of the card.
  final String hp;
  // A list of subtypes, such as Basic, EX, Mega, Rapid Strike, etc.
  final List<PokemonAbility> abilities;
  // One or more attacks for a given card.
  final List<PokemonAttacks> pokemonAttacks;
  // The image url of the card.
  final String imageUrl;

  Pokemon({
    required this.id,
    required this.name,
    required this.supertype,
    required this.subtypesList,
    required this.hp,
    required this.abilities,
    required this.pokemonAttacks,
    required this.imageUrl
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) =>
      _$PokemonFromJson(json);

  Map<String, dynamic> toJson() => _$PokemonToJson(this);
}