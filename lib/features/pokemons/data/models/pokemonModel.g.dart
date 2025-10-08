// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemonModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pokemon _$PokemonFromJson(Map<String, dynamic> json) => Pokemon(
  id: json['id'] as String,
  name: json['name'] as String,
  supertype: json['supertype'] as String,
  subtypesList: (json['subtypesList'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  hp: json['hp'] as String,
  abilities: (json['abilities'] as List<dynamic>)
      .map((e) => PokemonAbility.fromJson(e as Map<String, dynamic>))
      .toList(),
  pokemonAttacks: (json['pokemonAttacks'] as List<dynamic>)
      .map((e) => PokemonAttacks.fromJson(e as Map<String, dynamic>))
      .toList(),
  imageUrl: json['imageUrl'] as String,
);

Map<String, dynamic> _$PokemonToJson(Pokemon instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'supertype': instance.supertype,
  'subtypesList': instance.subtypesList,
  'hp': instance.hp,
  'abilities': instance.abilities,
  'pokemonAttacks': instance.pokemonAttacks,
  'imageUrl': instance.imageUrl,
};
