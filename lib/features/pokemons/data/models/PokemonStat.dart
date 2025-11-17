class PokemonStat {
  final int baseStat; // значение характеристики
  final int effort; // effort points
  final String name; // имя характеристики (hp, attack, defense...)

  PokemonStat({
    required this.baseStat,
    required this.effort,
    required this.name,
  });

  factory PokemonStat.fromJson(Map<String, dynamic> json) {
    return PokemonStat(
      baseStat: json['base_stat'] ?? 0,
      effort: json['effort'] ?? 0,
      name: json['stat']?['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_stat': baseStat,
      'effort': effort,
      'stat': {'name': name},
    };
  }
}
