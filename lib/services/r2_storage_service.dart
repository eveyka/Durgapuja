import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CompressedImageResult {
  final Uint8List originalBytes;
  final Uint8List compressedBytes;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final String fileName;

  const CompressedImageResult({
    required this.originalBytes,
    required this.compressedBytes,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.fileName,
  });

  double get originalSizeKb => originalSizeBytes / 1024;
  double get compressedSizeKb => compressedSizeBytes / 1024;
  double get originalSizeMb => originalSizeBytes / (1024 * 1024);
  double get compressedSizeMb => compressedSizeBytes / (1024 * 1024);

  double get savedPercentage {
    if (originalSizeBytes <= 0) return 0.0;
    final diff = originalSizeBytes - compressedSizeBytes;
    return diff > 0 ? (diff / originalSizeBytes) * 100 : 0.0;
  }

  String get summaryLabel {
    final origStr = originalSizeMb >= 1.0
        ? '${originalSizeMb.toStringAsFixed(1)} MB'
        : '${originalSizeKb.toStringAsFixed(0)} KB';
    final compStr = compressedSizeKb >= 1000
        ? '${compressedSizeMb.toStringAsFixed(1)} MB'
        : '${compressedSizeKb.toStringAsFixed(0)} KB';
    return '$origStr → $compStr (${savedPercentage.toStringAsFixed(0)}% reduced)';
  }
}

class _CompressParams {
  final Uint8List rawBytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;

  const _CompressParams({
    required this.rawBytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
}

Uint8List _isolateCompressImage(_CompressParams params) {
  return R2StorageService.compressImage(
    rawBytes: params.rawBytes,
    maxWidth: params.maxWidth,
    maxHeight: params.maxHeight,
    quality: params.quality,
  );
}

class R2StorageService {
  static const String accountId = '36a8bb867350b82ee35884892f318b8c';
  static const String bucketName = 'durga-puja';
  static const String apiToken = 'cfat_ZMD0GdgcL1XEPUInCAWvlYoSATgSVmuovr2d45HE5180405c';
  static const String publicBaseUrl = 'https://pub-4a875079330644ab9a88af50db3096ec.r2.dev';

  static final _picker = ImagePicker();
  static const _uuid = Uuid();

  /// Smart Image Compression
  /// Resizes large photos while preserving 100% readability for bills/invoices.
  /// Downscales if either dimension exceeds 1920px (Full HD+ resolution).
  /// Encodes to high-quality JPEG (82%) with EXIF auto-orientation.
  static Uint8List compressImage({
    required Uint8List rawBytes,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 82,
  }) {
    try {
      final image = img.decodeImage(rawBytes);
      if (image == null) return rawBytes;

      // Fix rotation from camera EXIF orientation
      final oriented = img.bakeOrientation(image);

      int targetW = oriented.width;
      int targetH = oriented.height;

      // Check if downscaling is needed
      if (targetW > maxWidth || targetH > maxHeight) {
        final double ratioW = maxWidth / targetW;
        final double ratioH = maxHeight / targetH;
        final double scale = ratioW < ratioH ? ratioW : ratioH;

        targetW = (targetW * scale).round();
        targetH = (targetH * scale).round();
      }

      final resized = (targetW != oriented.width || targetH != oriented.height)
          ? img.copyResize(
              oriented,
              width: targetW,
              height: targetH,
              interpolation: img.Interpolation.cubic,
            )
          : oriented;

      final compressed = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('R2StorageService compression error: $e');
      return rawBytes;
    }
  }

  /// 1. Pick raw file from Camera or Gallery (returns null if user cancels picker)
  static Future<XFile?> pickRawImage({
    required ImageSource source,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: 100, // We do manual smart compression
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// 2. Compress a picked file on a background isolate without freezing the UI
  static Future<CompressedImageResult> compressPickedFile(
    XFile pickedFile, {
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 82,
  }) async {
    final rawBytes = await pickedFile.readAsBytes();
    final compressedBytes = await compute(
      _isolateCompressImage,
      _CompressParams(
        rawBytes: rawBytes,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      ),
    );

    return CompressedImageResult(
      originalBytes: rawBytes,
      compressedBytes: compressedBytes,
      originalSizeBytes: rawBytes.length,
      compressedSizeBytes: compressedBytes.length,
      fileName: pickedFile.name,
    );
  }

  /// Pick image from Camera or Gallery and compress immediately
  static Future<CompressedImageResult?> pickAndCompressImage({
    required ImageSource source,
    int maxWidth = 1920,
    int maxHeight = 1920,
    int quality = 82,
  }) async {
    try {
      final pickedFile = await pickRawImage(source: source);
      if (pickedFile == null) return null;

      return await compressPickedFile(
        pickedFile,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
    } catch (e) {
      debugPrint('Error picking and compressing image: $e');
      return null;
    }
  }

  /// Uploads compressed image bytes directly to Cloudflare R2 bucket.
  /// Returns the permanent public CDN URL on success.
  static Future<String> uploadBillImage({
    required Uint8List imageBytes,
    String? customFileName,
    String folder = 'bills',
  }) async {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _uuid.v4().substring(0, 8);
    final prefix = folder.endsWith('s') ? folder.substring(0, folder.length - 1) : folder;
    final key = '$folder/$year/${prefix}_${timestamp}_$randomSuffix.jpg';

    final uri = Uri.parse(
      'https://api.cloudflare.com/client/v4/accounts/$accountId/r2/buckets/$bucketName/objects/$key',
    );

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'image/jpeg',
      },
      body: imageBytes,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final publicUrl = '$publicBaseUrl/$key';
      debugPrint('Successfully uploaded $folder image to Cloudflare R2: $publicUrl');
      return publicUrl;
    } else {
      debugPrint('R2 Upload failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to upload image to Cloudflare R2: ${response.body}');
    }
  }

  /// Uploads compressed slip image bytes directly to Cloudflare R2 under 'slips/'
  static Future<String> uploadSlipImage({
    required Uint8List imageBytes,
    String? customFileName,
  }) => uploadBillImage(
    imageBytes: imageBytes,
    customFileName: customFileName,
    folder: 'slips',
  );

  /// Delete a bill image from Cloudflare R2 given its public URL
  static Future<bool> deleteBillImage(String imageUrl) async {
    try {
      if (!imageUrl.startsWith(publicBaseUrl)) return false;

      final key = imageUrl.replaceFirst('$publicBaseUrl/', '');
      final uri = Uri.parse(
        'https://api.cloudflare.com/client/v4/accounts/$accountId/r2/buckets/$bucketName/objects/$key',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $apiToken',
        },
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('R2 delete error: $e');
      return false;
    }
  }
}
