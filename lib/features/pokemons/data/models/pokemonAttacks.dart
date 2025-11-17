class PokemonMove {
  final String name;
  final String url;

  PokemonMove({
    required this.name,
    required this.url,
  });

  factory PokemonMove.fromJson(Map<String, dynamic> json) {
    final moveJson = json['move'] as Map<String, dynamic>? ?? {};
    return PokemonMove(
      name: moveJson['name'] ?? '',
      url: moveJson['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }
}
