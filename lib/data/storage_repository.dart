import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_providers.dart';

/// Private bucket created in migration 0006. Images only, 5 MB ceiling,
/// per-user folder policies.
const String kVerificationBucket = 'verification-docs';

/// Every storage policy on this bucket keys off `(storage.foldername(name))[1]`
/// being the caller's uid, so the leading `uid/` segment is not cosmetic - get
/// it wrong and the upload fails with a 403 that reads like a network error.
///
/// The timestamp suffix keeps replacements from being cached as the old image.
String verificationObjectPath({
  required String uid,
  required String slot,
  String extension = 'jpg',
}) =>
    '$uid/${slot}_${DateTime.now().millisecondsSinceEpoch}.$extension';

/// The seam for moving to Azure Blob (or S3, or Cloudflare R2) later.
///
/// Everything above this interface deals in object paths, never in Supabase
/// types, so that migration is one new class here plus one provider override -
/// not a hunt through the widget tree.
abstract class StorageRepository {
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  /// A short-lived viewable link. Null when the object is gone or the caller
  /// is not allowed to see it - both are non-fatal for the admin console.
  Future<String?> signedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 300,
  });

  Future<void> remove({required String bucket, required String path});
}

class SupabaseStorageRepository implements StorageRepository {
  const SupabaseStorageRepository();

  @override
  Future<String> upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (!supabaseReady) {
      throw StateError('Backend not configured.');
    }
    await supabase.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return path;
  }

  @override
  Future<String?> signedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 300,
  }) async {
    if (!supabaseReady || path.isEmpty) return null;
    try {
      return await supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiresInSeconds);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove({required String bucket, required String path}) async {
    if (!supabaseReady || path.isEmpty) return;
    try {
      await supabase.storage.from(bucket).remove([path]);
    } catch (_) {
      // Best effort. A stranded object is cheaper than a failed submission.
    }
  }
}

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => const SupabaseStorageRepository(),
);
