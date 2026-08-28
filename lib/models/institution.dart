/// A Gurukul, Veda Pathashala or Sanskrit university, seeded in
/// `0004_institutions.sql` and readable with the anon key.
///
/// The registration screen offers this list but never forces it: the registry
/// can not possibly be complete, so the UI keeps a free-text escape hatch. The
/// value of the list is spelling normalisation, which is what lets an admin
/// recognise an institution at a glance instead of reading twelve variants of
/// "Sampurnanand".
class Institution {
  const Institution({
    required this.id,
    required this.name,
    this.city,
    this.state,
    this.kind = 'gurukul',
  });

  final int id;
  final String name;
  final String? city;
  final String? state;

  /// gurukul | pathshala | university | other
  final String kind;

  String get label {
    final where = [city, state].where((e) => (e ?? '').isNotEmpty).join(', ');
    return where.isEmpty ? name : '$name — $where';
  }

  static Institution fromMap(Map<String, dynamic> m) => Institution(
        id: (m['id'] as num).toInt(),
        name: m['name'] as String? ?? '',
        city: m['city'] as String?,
        state: m['state'] as String?,
        kind: m['kind'] as String? ?? 'gurukul',
      );
}
