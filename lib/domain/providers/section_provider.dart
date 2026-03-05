import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firebase/firestore/section_firestore.dart';
import '../../data/firebase/storage/firebase_storage_service.dart';
import '../../data/models/section_model.dart';
import '../../data/models/announcement_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/user_model.dart';
import 'auth_provider.dart';

// ── Service provider ──────────────────────────────────────────

final sectionFirestoreServiceProvider = Provider<SectionFirestoreService>((ref) {
  return SectionFirestoreService();
});

final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

// ── Owned Section ─────────────────────────────────────────────

final ownedSectionProvider = FutureProvider<SectionModel?>((ref) async {
  final service = ref.watch(sectionFirestoreServiceProvider);
  return service.getOwnedSection();
});

// ── Section ID (from user model) ──────────────────────────────

final sectionIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.value?.sectionId;
});

// ── Student count ─────────────────────────────────────────────

final studentCountProvider = StreamProvider<int>((ref) {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return Stream.value(0);
  return ref.watch(sectionFirestoreServiceProvider).watchStudentCount(sectionId);
});

// ── Section channels ──────────────────────────────────────────

final sectionChannelsProvider = StreamProvider<List<ChannelModel>>((ref) {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return Stream.value([]);
  return ref.watch(sectionFirestoreServiceProvider).watchSectionChannels(sectionId);
});

// ── Announcements ─────────────────────────────────────────────

final sectionAnnouncementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return Stream.value([]);
  return ref.watch(sectionFirestoreServiceProvider).watchAnnouncements(sectionId);
});

// ── Live Announcement ─────────────────────────────────────────

final liveAnnouncementProvider = StreamProvider<AnnouncementModel?>((ref) {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return Stream.value(null);
  return ref.watch(sectionFirestoreServiceProvider).watchLiveAnnouncement(sectionId);
});

// ── Events ────────────────────────────────────────────────────

final sectionEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return Stream.value([]);
  return ref.watch(sectionFirestoreServiceProvider).watchEvents(sectionId);
});

// ── Recent Activity ───────────────────────────────────────────

final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return [];
  return ref.watch(sectionFirestoreServiceProvider).getRecentActivity(sectionId);
});

// ── Students ──────────────────────────────────────────────────

final sectionStudentsProvider = StreamProvider<List<UserModel>>((ref) {
  final sectionId = ref.watch(sectionIdProvider);
  if (sectionId == null) return Stream.value([]);
  return ref.watch(sectionFirestoreServiceProvider).watchStudents(sectionId);
});
