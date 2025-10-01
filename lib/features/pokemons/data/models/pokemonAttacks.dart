import 'package:json_annotation/json_annotation.dart';

part 'pokemonAttacks.g.dart';

@JsonSerializable()
class PokemonAttacks {
  final List<String> cost;
  final String name;
  final String text;
  final String damage;
  final int convertedEnergyCost;

  PokemonAttacks({
    required this.cost,
    required this.name,
    required this.text,
    required this.damage,
    required this.convertedEnergyCost,
  });

  factory PokemonAttacks.fromJson(Map<String, dynamic> json) =>
      _$PokemonAttacksFromJson(json);

  Map<String, dynamic> toJson() => _$PokemonAttacksToJson(this);
}