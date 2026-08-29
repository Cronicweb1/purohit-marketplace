/// One work photo in a purohit's portfolio.
///
/// Only the storage object path is persisted, never a URL: the bucket is
/// public today, but keeping paths means switching to Azure Blob later is a
/// change in `StorageRepository` alone.
class PortfolioItem {
  const PortfolioItem({
    required this.id,
    required this.panditId,
    required this.objectPath,
    this.caption,
    this.sortOrder = 0,
  });

  final int id;
  final String panditId;
  final String objectPath;
  final String? caption;
  final int sortOrder;

  static PortfolioItem fromMap(Map<String, dynamic> m) => PortfolioItem(
        id: (m['id'] as num).toInt(),
        panditId: m['pandit_id'] as String,
        objectPath: m['object_path'] as String? ?? '',
        caption: m['caption'] as String?,
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
      );
}
