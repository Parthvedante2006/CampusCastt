import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/section_model.dart';
import '../../models/channel_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── SECTIONS ──────────────────────────────────────────────

  Stream<List<SectionModel>> getSections() {
    return _firestore.collection('sections').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SectionModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<SectionModel> createSection(String name, String collegeTrust) async {
    final docRef = await _firestore.collection('sections').add({
      'name': name,
      'college_trust': collegeTrust,
      'owner_name': null,
      'owner_email': null,
      'student_count': 0,
    });
    final doc = await docRef.get();
    return SectionModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> setSectionOwner({
    required String sectionId,
    required String name,
    required String email,
    required String password,
    required String collegeTrust,
  }) async {
    // Create Firebase Auth account for section owner
    // We need to use a secondary Firebase Auth instance workaround
    // Since creating a user with createUserWithEmailAndPassword signs in as that user,
    // we'll re-authenticate the admin after
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final ownerUid = credential.user!.uid;

    // Create users document for section owner
    await _firestore.collection('users').doc(ownerUid).set({
      'name': name,
      'email': email,
      'role': 'section_owner',
      'section_id': sectionId,
      'college_trust': collegeTrust,
      'joined_sections': [sectionId],
      'default_channels': [],
      'joined_channels': [],
    });

    // Update section with owner info
    await _firestore.collection('sections').doc(sectionId).update({
      'owner_name': name,
      'owner_email': email,
      'owner_password': password,
    });

    // Sign out the newly created user (it auto-signed in)
    await _auth.signOut();

    // Re-sign in as admin — the caller must handle re-authentication
    // We store a flag so the UI knows to prompt for re-auth
  }

  // ── CHANNELS ──────────────────────────────────────────────

  Stream<List<ChannelModel>> getChannels() {
    return _firestore.collection('channels').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createChannelWithOwner({
    required String channelName,
    required String sectionId,
    required String sectionName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    required String collegeTrust,
    bool isDefault = false,
  }) async {
    // Create channel document
    final channelRef = await _firestore.collection('channels').add({
      'name': channelName,
      'section_id': sectionId,
      'section_name': sectionName,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'owner_password': ownerPassword,
      'is_default': isDefault,
      'is_live': false,
      'active_broadcast_id': null,
      'member_count': 0,
    });

    // Create Firebase Auth account for channel owner
    final credential = await _auth.createUserWithEmailAndPassword(
      email: ownerEmail,
      password: ownerPassword,
    );

    final ownerUid = credential.user!.uid;

    // Create users document for channel owner
    await _firestore.collection('users').doc(ownerUid).set({
      'name': ownerName,
      'email': ownerEmail,
      'role': 'channel_owner',
      'section_id': sectionId,
      'channel_id': channelRef.id,
      'college_trust': collegeTrust,
      'joined_sections': [sectionId],
      'default_channels': [],
      'joined_channels': [],
    });

    // Sign out the newly created user
    await _auth.signOut();
  }

  // ── CSV WHITELIST ─────────────────────────────────────────

  Future<Map<String, int>> uploadStudentWhitelist({
    required String sectionId,
    required List<Map<String, String>> students,
  }) async {
    int added = 0;
    int existed = 0;

    for (final student in students) {
      final email = student['email'] ?? '';
      if (email.isEmpty) continue;

      final formattedEmail = email.replaceAll('.', '_');
      final docRef = _firestore
          .collection('whitelist')
          .doc(sectionId)
          .collection('emails')
          .doc(formattedEmail);

      final doc = await docRef.get();
      if (doc.exists) {
        existed++;
      } else {
        await docRef.set({
          'name': student['name'] ?? '',
          'email': email,
          'college': student['college'] ?? '',
          'section_id': sectionId,
          'is_registered': false,
        });
        added++;
      }
    }

    return {'added': added, 'existed': existed};
  }

  // ── UTILS ─────────────────────────────────────────────────

  static String generatePassword({int length = 10}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
