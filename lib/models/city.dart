class City {
  const City({
    required this.id,
    required this.name,
    required this.state,
  });

  final int id;
  final String name;
  final String state;

  String get label => '$name, $state';

  static City fromMap(Map<String, dynamic> m) => City(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String,
        state: m['state'] as String,
      );
}
