import 'dart:convert';
import 'package:pokemon_collector/features/pokemons/data/models/pokemonModel.dart';
import 'network_client.dart';
import 'network_exceptions.dart';

class NetworkService {
  final NetworkClient client;

  NetworkService({required this.client});

  Future<List<Pokemon>> fetchPokemons({int pageSize = 20}) async {
    try {
      final response = await client.get('https://api.pokemontcg.io/v2/cards?pageSize=1');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'] as List;
        
        return data.map((e) => Pokemon.fromJson(e)).toList();
      } else {
        throw NetworkException(
            'Ошибка получения карточек: ${response.statusCode}');
      }
    } catch (e) {
      throw NetworkException('Ошибка сети: $e');
    }
  }
}
