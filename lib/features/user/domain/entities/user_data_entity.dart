class UserDataEntity {
  final List<String> pokemonIds;
  final DateTime? lastCardReceived;
  final bool hasPokemons;
  final bool canTakeNewCard;
  final DateTime? nextCardTime;

  UserDataEntity({
    required this.pokemonIds,
    this.lastCardReceived,
    required this.hasPokemons,
    required this.canTakeNewCard,
    this.nextCardTime,
  });

  factory UserDataEntity.fromMap(Map<String, dynamic> data, DateTime now) {
    final pokemons = List<dynamic>.from(data['pokemons'] ?? []);
    final pokemonIds = pokemons.map((e) => e.toString()).toList();

    final lastTs = data['lastCardReceived'];
    DateTime? lastCardTime;
    DateTime? nextCardTime;
    bool canTakeNewCard = lastTs == null;

    if (lastTs != null) {
      lastCardTime = (lastTs as dynamic).toDate();
      nextCardTime = lastCardTime?.add(Duration(hours: 24));
      canTakeNewCard = now.isAfter(nextCardTime!);
    }

    return UserDataEntity(
      pokemonIds: pokemonIds,
      lastCardReceived: lastCardTime,
      hasPokemons: pokemonIds.isNotEmpty,
      canTakeNewCard: canTakeNewCard,
      nextCardTime: nextCardTime,
    );
  }
}
