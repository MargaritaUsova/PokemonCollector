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
  // The level of the card. This only pertains to cards from older sets and those of supertype Pokémon.
  final String level;
  // The hit points of the card.
  final String hp;
  // A list of subtypes, such as Basic, EX, Mega, Rapid Strike, etc.
  final List<PokemonAbility> abilities;
  // One or more attacks for a given card.
  final List<PokemonAttacks> pokemonAttacks;

  Pokemon({
    required this.id,
    required this.name,
    required this.supertype,
    required this.subtypesList,
    required this.level,
    required this.hp,
    required this.abilities,
    required this.pokemonAttacks,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) =>
      _$PokemonFromJson(json);

  Map<String, dynamic> toJson() => _$PokemonToJson(this);
}