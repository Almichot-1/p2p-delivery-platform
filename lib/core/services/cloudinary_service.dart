import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../constants/cloudinary_constants.dart';

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  static const Uuid _uuid = Uuid();

  /// Unsigned upload only.
  /// Returns the hosted image URL (secure_url) or throws.
  Future<String> uploadImage(File file, String folder, String? publicId) async {
    final cloudName = CloudinaryConstants.cloudName.trim();
    final uploadPreset = CloudinaryConstants.uploadPreset.trim();
    if (cloudName.isEmpty || cloudName == 'YOUR_CLOUD_NAME') {
      throw StateError(
        'Cloudinary is not configured. Set CLOUDINARY_CLOUD_NAME via --dart-define '
        'or update CloudinaryConstants.cloudName.',
      );
    }
    if (uploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary upload preset is empty. Set CLOUDINARY_UPLOAD_PRESET via --dart-define '
        'or update CloudinaryConstants.uploadPreset.',
      );
    }

    final uri = Uri.parse(CloudinaryConstants.baseUploadUrl);

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder;

    if (publicId != null && publicId.trim().isNotEmpty) {
      request.fields['public_id'] = publicId.trim();
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${streamed.statusCode} $body');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary response missing secure_url');
    }

    return secureUrl;
  }

  Future<String> uploadProfileImage(File file, String uid) {
    return uploadImage(
      file,
      CloudinaryConstants.folderProfiles,
      uid,
    );
  }

  Future<String> uploadRequestImage(File file, String requestId, int index) {
    final publicId = _requestImagePublicId(requestId: requestId, index: index);
    return uploadImage(
      file,
      CloudinaryConstants.folderRequests,
      publicId,
    );
  }

  Future<List<String>> uploadRequestImages(List<File> files, String requestId) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url = await uploadRequestImage(files[i], requestId, i);
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadChatImage(File file, String matchId) {
    return uploadImage(
      file,
      CloudinaryConstants.folderChats,
      null,
    );
  }

  static String _requestImagePublicId({required String requestId, required int index}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    return '$requestId-$index-$ts-$id';
  }

  static String getProfileThumbUrl(String urlOrPublicId) {
    return _applyTransformation(urlOrPublicId, CloudinaryConstants.tProfileThumb);
  }

  static String getItemMediumUrl(String urlOrPublicId) {
    return _applyTransformation(urlOrPublicId, CloudinaryConstants.tItemMedium);
  }

  static String getChatImageUrl(String urlOrPublicId) {
    return _applyTransformation(urlOrPublicId, CloudinaryConstants.tChatImage);
  }

  static String _applyTransformation(String urlOrPublicId, String transformation) {
    final value = urlOrPublicId.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      const marker = '/image/upload/';
      final idx = value.indexOf(marker);
      if (idx == -1) return value;
      final insertAt = idx + marker.length;
      return value.substring(0, insertAt) + '$transformation/' + value.substring(insertAt);
    }

    // Treat as public id.
    return '${CloudinaryConstants.baseImageDeliveryUrl}/image/upload/$transformation/$value';
  }
}
