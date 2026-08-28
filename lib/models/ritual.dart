/// A ceremony. Merged from the old `skills` + `services` tables.
///
///   bookable  — a family can post a job for it
///   claimable — a purohit can list it as a specialisation
///
/// Vedic Knowledge / Jyotishacharya / Kathavachak / Karmakandi are
/// specialisations: claimable, not bookable.
class Ritual {
  const Ritual({
    required this.id,
    required this.slug,
    required this.name,
    this.nameHi,
    this.aliases = const [],
    this.bookable = true,
    this.claimable = true,
    this.typicalDurationMinutes,
    this.isMultiDay = false,
  });

  final int id;
  final String slug;
  final String name;
  final String? nameHi;
  final List<String> aliases;
  final bool bookable;
  final bool claimable;
  final int? typicalDurationMinutes;
  final bool isMultiDay;

  /// Families search "mundan" / "janoi" / "godh bharai", never the Sanskrit
  /// name — so the alias list is part of the searchable surface, not decoration.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if ((nameHi ?? '').contains(q)) return true;
    return aliases.any((a) => a.toLowerCase().contains(q));
  }

  static Ritual fromMap(Map<String, dynamic> m) => Ritual(
        id: (m['id'] as num).toInt(),
        slug: m['slug'] as String,
        name: m['name'] as String,
        nameHi: m['name_hi'] as String?,
        aliases: (m['aliases'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        bookable: m['bookable'] as bool? ?? true,
        claimable: m['claimable'] as bool? ?? true,
        typicalDurationMinutes: (m['typical_duration_minutes'] as num?)?.toInt(),
        isMultiDay: m['is_multi_day'] as bool? ?? false,
      );
}
