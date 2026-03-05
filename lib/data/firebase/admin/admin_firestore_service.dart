import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/section_model.dart';
import '../../models/channel_model.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── SECONDARY APP (prevents admin logout) ──────────────────
  Future<FirebaseAuth> _getSecondaryAuth() async {
    FirebaseApp secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('secondary');
    }
    return FirebaseAuth.instanceFor(app: secondaryApp);
  }

  // ── SECTIONS ───────────────────────────────────────────────

  Stream<List<SectionModel>> getSections() {
    return _firestore.collection('sections').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => SectionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<SectionModel> createSection(
      String name, String collegeTrust) async {
    final docRef = await _firestore.collection('sections').add({
      'name': name,
      'college_trust': collegeTrust,
      'owner_name': null,
      'owner_email': null,
      'owner_password': null,
      'owner_uid': null,
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
    final secondaryAuth = await _getSecondaryAuth();
    String ownerUid;

    try {
      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      ownerUid = credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final credential =
            await secondaryAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        ownerUid = credential.user!.uid;
        await credential.user!.updatePassword(password);
      } else {
        rethrow;
      }
    }

    await secondaryAuth.signOut();

    await _firestore.collection('users').doc(ownerUid).set({
      'name': name,
      'email': email,
      'role': 'section_owner',
      'section_id': sectionId,
      'college_trust': collegeTrust,
      'password': password,
      'joined_sections': [sectionId],
      'default_channels': [],
      'joined_channels': [],
    }, SetOptions(merge: true));

    await _firestore.collection('sections').doc(sectionId).update({
      'owner_name': name,
      'owner_email': email,
      'owner_password': password,
      'owner_uid': ownerUid,
    });
  }

  // ── CHANNELS ───────────────────────────────────────────────

  Stream<List<ChannelModel>> getChannels() {
    return _firestore.collection('channels').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ChannelModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
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
    final secondaryAuth = await _getSecondaryAuth();
    String ownerUid;

    try {
      final credential =
          await secondaryAuth.createUserWithEmailAndPassword(
        email: ownerEmail,
        password: ownerPassword,
      );
      ownerUid = credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final credential =
            await secondaryAuth.signInWithEmailAndPassword(
          email: ownerEmail,
          password: ownerPassword,
        );
        ownerUid = credential.user!.uid;
        await credential.user!.updatePassword(ownerPassword);
      } else {
        rethrow;
      }
    }

    await secondaryAuth.signOut();

    final channelRef =
        await _firestore.collection('channels').add({
      'name': channelName,
      'section_id': sectionId,
      'section_name': sectionName,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'owner_password': ownerPassword,
      'owner_uid': ownerUid,
      'is_default': isDefault,
      'is_live': false,
      'active_broadcast_id': null,
      'member_count': 0,
    });

    await _firestore.collection('users').doc(ownerUid).set({
      'name': ownerName,
      'email': ownerEmail,
      'role': 'channel_owner',
      'section_id': sectionId,
      'channel_id': channelRef.id,
      'college_trust': collegeTrust,
      'password': ownerPassword,
      'joined_sections': [sectionId],
      'default_channels': [],
      'joined_channels': [],
    }, SetOptions(merge: true));
  }

  // ── CSV WHITELIST ──────────────────────────────────────────

 Future<Map<String, int>> uploadStudentWhitelist({
  required String sectionId,
  required String sectionName, // ✅ added
  required List<Map<String, String>> students,
}) async {
  int added = 0;
  int existed = 0;

  WriteBatch batch = _firestore.batch();
  int batchCount = 0;

  for (final student in students) {
    final email = (student['email'] ?? '').trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) continue;

    final sanitizedEmail = email
        .replaceAll('@', '_at_')
        .replaceAll('.', '_');

    final docRef = _firestore
        .collection('whitelist')
        .doc(sectionId)
        .collection('emails')
        .doc(sanitizedEmail);

    final doc = await docRef.get();

    if (doc.exists) {
      existed++;
    } else {
      batch.set(docRef, {
        'name': (student['name'] ?? '').trim(),
        'email': email,
        'college': (student['college'] ?? '').trim(),
        'section_id': sectionId,
        'section_name': sectionName, // ✅ now stored
        'is_registered': false,
        'uploaded_at': FieldValue.serverTimestamp(),
      });
      added++;
      batchCount++;

      if (batchCount >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  await _firestore
      .collection('sections')
      .doc(sectionId)
      .update({
    'student_count': FieldValue.increment(added),
  });

  return {'added': added, 'existed': existed};
}

  // ── CHECK WHITELIST ────────────────────────────────────────

  Future<Map<String, dynamic>?> checkStudentWhitelist({
    required String email,
    required String sectionId,
  }) async {
    final sanitizedEmail = email
        .trim()
        .toLowerCase()
        .replaceAll('@', '_at_')
        .replaceAll('.', '_');

    final doc = await _firestore
        .collection('whitelist')
        .doc(sectionId)
        .collection('emails')
        .doc(sanitizedEmail)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> findStudentInWhitelist({
    required String email,
  }) async {
    final sanitizedEmail = email
        .trim()
        .toLowerCase()
        .replaceAll('@', '_at_')
        .replaceAll('.', '_');

    final sections =
        await _firestore.collection('sections').get();

    for (final section in sections.docs) {
      final doc = await _firestore
          .collection('whitelist')
          .doc(section.id)
          .collection('emails')
          .doc(sanitizedEmail)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          ...data,
          'section_id': section.id,
          'section_name': section.data()['name'] ?? '',
          'doc_id': sanitizedEmail,
        };
      }
    }

    return null;
  }

  Future<void> markStudentRegistered({
    required String email,
    required String sectionId,
  }) async {
    final sanitizedEmail = email
        .trim()
        .toLowerCase()
        .replaceAll('@', '_at_')
        .replaceAll('.', '_');

    await _firestore
        .collection('whitelist')
        .doc(sectionId)
        .collection('emails')
        .doc(sanitizedEmail)
        .update({'is_registered': true});
  }

  // ── UTILS ──────────────────────────────────────────────────

  static String generatePassword({int length = 10}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$';
    final random = Random.secure();
    return List.generate(
            length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }
}