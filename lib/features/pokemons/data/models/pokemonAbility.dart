import 'package:json_annotation/json_annotation.dart';

part 'pokemonAbility.g.dart';

@JsonSerializable()
class PokemonAbility {
  final String name;
  final String text;
  final String type;

  PokemonAbility({
    required this.name,
    required this.text,
    required this.type,
  });

  factory PokemonAbility.fromJson(Map<String, dynamic> json) =>
      _$PokemonAbilityFromJson(json);

  Map<String, dynamic> toJson() => _$PokemonAbilityToJson(this);
}