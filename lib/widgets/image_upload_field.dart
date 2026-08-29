import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

/// An image chosen on the device, already downscaled and re-encoded.
class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.contentType,
    required this.extension,
  });

  final Uint8List bytes;
  final String contentType;
  final String extension;

  int get sizeBytes => bytes.length;

  String get readableSize {
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

/// The bucket rejects anything larger (migration 0006 sets `file_size_limit`),
/// so catching it here turns a cryptic 413 into a sentence a purohit can act on.
const _maxUploadBytes = 5 * 1024 * 1024;

/// Compression happens inside image_picker itself: it decodes, downscales to fit
/// 1600x1600 and re-encodes at quality 70 in native code. That is why this
/// feature added ONE dependency instead of two - no `flutter_image_compress`.
///
/// A 12 MP phone photo (~4-6 MB) lands at roughly 200-400 KB, which matters a
/// lot on the connections plenty of purohits are on.
const _maxDimension = 1600.0;
const _quality = 70;

/// Trust the bytes, not the filename: Android re-encodes to JPEG when
/// `imageQuality` is set but frequently keeps the original `.png` name, and
/// uploading that with the wrong content-type gets rejected by the bucket's
/// `allowed_mime_types`.
({String contentType, String extension}) _sniff(Uint8List b) {
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return (contentType: 'image/png', extension: 'png');
  }
  if (b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46 &&
      b[8] == 0x57 &&
      b[9] == 0x45 &&
      b[10] == 0x42 &&
      b[11] == 0x50) {
    return (contentType: 'image/webp', extension: 'webp');
  }
  return (contentType: 'image/jpeg', extension: 'jpg');
}

/// Label + preview + pick/replace/remove, used for the ID card, the address
/// proof and the certificate scan.
class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String? helper;
  final PickedImage? value;
  final ValueChanged<PickedImage?> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  final _picker = ImagePicker();
  bool _busy = false;
  String? _localError;

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _localError = null;
    });
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
        imageQuality: _quality,
      );
      if (file == null) return; // User backed out. Not an error.

      final bytes = await file.readAsBytes();
      if (bytes.length > _maxUploadBytes) {
        setState(() => _localError =
            'That image is ${(bytes.length / 1048576).toStringAsFixed(1)} MB '
            'even after compression. Please crop it or take a plainer photo.');
        return;
      }
      final kind = _sniff(bytes);
      widget.onChanged(PickedImage(
        bytes: bytes,
        contentType: kind.contentType,
        extension: kind.extension,
      ));
    } on PlatformException catch (e) {
      setState(() =>
          _localError = e.message ?? 'Could not open that image. Try another one.');
    } catch (_) {
      setState(() => _localError = 'Could not read that image. Try another one.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: Gap.sm),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText ?? _localError;
    final value = widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink)),
        if (widget.helper != null) ...[
          const SizedBox(height: Gap.xs),
          Text(widget.helper!,
              style: const TextStyle(fontSize: 12, color: AppColors.inkFaint)),
        ],
        const SizedBox(height: Gap.sm),
        AnimatedContainer(
          duration: AppDuration.fast,
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: value == null ? AppColors.surface : AppColors.saffronTint,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: error != null
                  ? AppColors.danger
                  : (value == null ? AppColors.hairline : AppColors.saffron),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.field),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: value == null
                      ? Container(
                          color: AppColors.hairline.withValues(alpha: 0.4),
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.inkFaint),
                        )
                      : Image.memory(value.bytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Text(
                  value == null
                      ? 'No photo attached yet'
                      : 'Attached \u00b7 ${value.readableSize}',
                  style: TextStyle(
                    fontSize: 13,
                    color: value == null ? AppColors.inkMuted : AppColors.ink,
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                if (value != null)
                  IconButton(
                    tooltip: 'Remove',
                    onPressed:
                        widget.enabled ? () => widget.onChanged(null) : null,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                TextButton(
                  onPressed: widget.enabled ? _choose : null,
                  child: Text(value == null ? 'Add photo' : 'Replace'),
                ),
              ],
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: Gap.xs),
          Text(error,
              style: const TextStyle(fontSize: 12, color: AppColors.danger)),
        ],
      ],
    );
  }
}


/// Sheet-only variant of the field above, for places that already have their own
/// affordance (the avatar circle, the "add photo" tile in the portfolio) and so
/// do not want the label/preview chrome.
///
/// Returns null when the user backs out. Throws with a human sentence when the
/// image cannot be used, so callers can pipe it straight into a SnackBar.
Future<PickedImage?> pickCompressedImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: Gap.sm),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: _maxDimension,
    maxHeight: _maxDimension,
    imageQuality: _quality,
  );
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  if (bytes.length > _maxUploadBytes) {
    throw Exception(
      'That image is ${(bytes.length / 1048576).toStringAsFixed(1)} MB even '
      'after compression. Please crop it or take a plainer photo.',
    );
  }
  final kind = _sniff(bytes);
  return PickedImage(
    bytes: bytes,
    contentType: kind.contentType,
    extension: kind.extension,
  );
}
