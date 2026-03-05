import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload event poster image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String> uploadEventPoster({
    required File imageFile,
    required String sectionId,
    required String eventId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'event_poster_${eventId}_$timestamp.jpg';
      final path = 'events/$sectionId/$eventId/$fileName';

      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'sectionId': sectionId,
          },
        ),
      );

      // Wait for the upload to complete
      final taskSnapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload event poster: $e');
    }
  }

  /// Upload announcement audio to Firebase Storage
  /// Returns the download URL of the uploaded audio
  Future<String> uploadAnnouncementAudio({
    required File audioFile,
    required String sectionId,
    required String announcementId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'announcement_audio_${announcementId}_$timestamp.m4a';
      final path = 'announcements/$sectionId/$announcementId/$fileName';

      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/mp4',
          customMetadata: {
            'announcementId': announcementId,
            'sectionId': sectionId,
          },
        ),
      );

      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload announcement audio: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String fullPath) async {
    try {
      final ref = _storage.ref().child(fullPath);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final path = 'profiles/$userId/$fileName';

      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
          },
        ),
      );

      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Track upload progress
  Future<String> uploadEventPosterWithProgress({
    required File imageFile,
    required String sectionId,
    required String eventId,
    required Function(double) onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'event_poster_${eventId}_$timestamp.jpg';
      final path = 'events/$sectionId/$eventId/$fileName';

      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'sectionId': sectionId,
          },
        ),
      );

      // Listen to progress updates
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload event poster: $e');
    }
  }
}
