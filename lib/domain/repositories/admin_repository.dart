import '../../data/firebase/admin/admin_firestore_service.dart';
import '../../data/models/section_model.dart';
import '../../data/models/channel_model.dart';

class AdminRepository {
  final AdminFirestoreService _service;

  AdminRepository(this._service);

  // ── SECTIONS ──────────────────────────────────────────────

  Stream<List<SectionModel>> getSections() =>
      _service.getSections();

  Future<SectionModel> createSection(
          String name, String collegeTrust) =>
      _service.createSection(name, collegeTrust);

  Future<void> setSectionOwner({
    required String sectionId,
    required String name,
    required String email,
    required String password,
    required String collegeTrust,
  }) =>
      _service.setSectionOwner(
        sectionId: sectionId,
        name: name,
        email: email,
        password: password,
        collegeTrust: collegeTrust,
      );

  // ── CHANNELS ──────────────────────────────────────────────

  Stream<List<ChannelModel>> getChannels() =>
      _service.getChannels();

  Future<void> createChannelWithOwner({
    required String channelName,
    required String sectionId,
    required String sectionName,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    required String collegeTrust,
    bool isDefault = false,
  }) =>
      _service.createChannelWithOwner(
        channelName: channelName,
        sectionId: sectionId,
        sectionName: sectionName,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        ownerPassword: ownerPassword,
        collegeTrust: collegeTrust,
        isDefault: isDefault,
      );

  // ── CSV WHITELIST ──────────────────────────────────────────

  Future<Map<String, int>> uploadStudentWhitelist({
  required String sectionId,
  required String sectionName, // ✅ added
  required List<Map<String, String>> students,
}) =>
    _service.uploadStudentWhitelist(
      sectionId: sectionId,
      sectionName: sectionName, // ✅ added
      students: students,
    );

  Future<Map<String, dynamic>?> checkStudentWhitelist({
    required String email,
    required String sectionId,
  }) =>
      _service.checkStudentWhitelist(
        email: email,
        sectionId: sectionId,
      );

  Future<Map<String, dynamic>?> findStudentInWhitelist({
    required String email,
  }) =>
      _service.findStudentInWhitelist(email: email);

  Future<void> markStudentRegistered({
    required String email,
    required String sectionId,
  }) =>
      _service.markStudentRegistered(
        email: email,
        sectionId: sectionId,
      );
}

