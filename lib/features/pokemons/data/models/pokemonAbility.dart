class PokemonAbility {
  final String name;
  final String url;
  final bool isHidden;

  PokemonAbility({
    required this.name,
    required this.url,
    required this.isHidden,
  });

  factory PokemonAbility.fromJson(Map<String, dynamic> json) {
    return PokemonAbility(
      name: json['ability']['name'] ?? '',
      url: json['ability']['url'] ?? '',
      isHidden: json['is_hidden'] ?? false,
    );
  }
}
