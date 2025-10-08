import 'package:pokemon_tcg/pokemon_tcg.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonAbility.dart';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonAttacks.dart';

class PokemonRemoteDataSource {
  final PokemonTcgApi api;

  PokemonRemoteDataSource({required this.api});

  /// Получить список карт
  Future<List<Pokemon>> getPokemons({int pageSize = 20}) async {
    try {
      final result = await api.getCards();
      return result.map((card) => _mapCardToPokemon(card)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить конкретную карту по ID
  Future<Pokemon?> getCard(String cardId) async {
    try {
      final card = await api.getCard(cardId);
      return _mapCardToPokemon(card);
    } catch (e) {
      return null;
    }
  }

  /// Получить карты из конкретного набора
  Future<List<Pokemon>> getCardsForSet(String setId) async {
    try {
      final result = await api.getCardsForSet(setId);
      final cards = result as List<PokemonCard>;
      return cards.map((card) => _mapCardToPokemon(card)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить все наборы
  Future<List<CardSet>> getSets() async {
    try {
      final result = await api.getSets();
      return result as List<CardSet>;
    } catch (e) {
      return [];
    }
  }

  /// Получить конкретный набор
  Future<CardSet?> getSet(String setId) async {
    try {
      return await api.getSet(setId);
    } catch (e) {
      return null;
    }
  }

  /// Получить типы карт
  Future<List<String>> getTypes() async {
    try {
      final types = await api.getTypes();
      return types.map((type) => type.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить подтипы карт
  Future<List<String>> getSubtypes() async {
    try {
      final subtypes = await api.getSubtypes();
      return subtypes.map((subtype) => subtype.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить супертипы карт
  Future<List<String>> getSupertypes() async {
    try {
      final supertypes = await api.getSupertypes();
      return supertypes.map((supertype) => supertype.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Получить редкости карт
  Future<List<String>> getRarities() async {
    try {
      final rarities = await api.getRarities();
      return rarities.map((rarity) => rarity.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Маппинг карты SDK в модель Pokemon
  Pokemon _mapCardToPokemon(PokemonCard card) {
    final abilities = <PokemonAbility>[];
    if (card.abilities != null) {
      for (final a in card.abilities!) {
        abilities.add(PokemonAbility(
          name: a.name ?? '',
          text: a.text ?? '',
          type: a.type ?? '',
        ));
      }
    }

    final attacks = <PokemonAttacks>[];
    if (card.attacks != null) {
      for (final at in card.attacks!) {
        attacks.add(PokemonAttacks(
          cost: (at.cost ?? []).cast<String>(),
          name: at.name ?? '',
          text: at.text ?? '',
          damage: at.damage ?? '',
          convertedEnergyCost: at.convertedEnergyCost ?? 0,
        ));
      }
    }

    return Pokemon(
      id: card.id.toString(),
      name: card.name.toString(),
      supertype: card.supertype.toString(),
      subtypesList: (card.subtypes ?? []).cast<String>(),
      hp: card.hp ?? '',
      abilities: abilities,
      pokemonAttacks: attacks,
      imageUrl: card.images.large
    );
  }
}