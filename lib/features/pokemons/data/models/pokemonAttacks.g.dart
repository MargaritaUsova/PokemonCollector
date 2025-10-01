// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemonAttacks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PokemonAttacks _$PokemonAttacksFromJson(Map<String, dynamic> json) =>
    PokemonAttacks(
      cost: (json['cost'] as List<dynamic>).map((e) => e as String).toList(),
      name: json['name'] as String,
      text: json['text'] as String,
      damage: json['damage'] as String,
      convertedEnergyCost: (json['convertedEnergyCost'] as num).toInt(),
    );

Map<String, dynamic> _$PokemonAttacksToJson(PokemonAttacks instance) =>
    <String, dynamic>{
      'cost': instance.cost,
      'name': instance.name,
      'text': instance.text,
      'damage': instance.damage,
      'convertedEnergyCost': instance.convertedEnergyCost,
    };
