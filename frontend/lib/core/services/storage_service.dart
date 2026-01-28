import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'firebase_service.dart';

class StorageService {
  final FirebaseService _firebaseService;

  StorageService(this._firebaseService);

  Future<String> uploadProfileImage(File file) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final ext = path.extension(file.path);
    final uuid = const Uuid().v4();
    final ref = _firebaseService.usersStorageRef.child('$userId/profile/$uuid$ext');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadVerificationDoc(File file) async {
    final userId = _firebaseService.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final uuid = const Uuid().v4();
    final ext = path.extension(file.path);
    final ref = _firebaseService.usersStorageRef.child('$userId/verification/$uuid$ext');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadItemImage(File file, String requestId) async {
    final uuid = const Uuid().v4();
    final ext = path.extension(file.path);
    final ref = _firebaseService.requestsStorageRef.child('$requestId/images/$uuid$ext');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String requestId,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      final url = await uploadItemImage(file, requestId);
      urls.add(url);
    }
    return urls;
  }

  Future<String> uploadChatImage(File file, String matchId) async {
    final uuid = const Uuid().v4();
    final ext = path.extension(file.path);
    final ref = _firebaseService.matchesStorageRef.child('$matchId/attachments/$uuid$ext');

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _firebaseService.storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // File might not exist
    }
  }
}
