import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firebase/firestore/student_firestore.dart';
import '../../data/models/section_model.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/event_model.dart';

final _firestoreService = StudentFirestoreService();

// Current Selected Section ID State
class SelectedSectionIdNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateId(String newId) {
    state = newId;
  }
}

final selectedSectionIdProvider = NotifierProvider<SelectedSectionIdNotifier, String>(() {
  return SelectedSectionIdNotifier();
});

// Sections
final studentSectionsProvider = StreamProvider<List<SectionModel>>((ref) {
  return _firestoreService.streamAllSections();
});

// Channels for selected Section
final sectionChannelsProvider = StreamProvider.family<List<ChannelModel>, String>((ref, sectionId) {
  return _firestoreService.streamChannelsBySection(sectionId);
});

// Live Broadcasts
final studentLiveBroadcastsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _firestoreService.streamLiveBroadcasts();
});

// All Events (filter on UI)
final studentEventsProvider = StreamProvider<List<EventModel>>((ref) {
  return _firestoreService.streamAllEvents();
});

// Joined Channels
final studentJoinedChannelsProvider = StreamProvider.family<List<ChannelModel>, List<String>>((ref, joinedIds) {
  return _firestoreService.streamJoinedChannels(joinedIds);
});

// Global/Default Channels
final studentGlobalChannelsProvider = StreamProvider<List<ChannelModel>>((ref) {
  return _firestoreService.streamGlobalChannels();
});

// Replays
final studentReplaysProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return _firestoreService.streamReplays();
});

// Channel specific actions
final studentFirestoreProvider = Provider<StudentFirestoreService>((ref) {
  return _firestoreService;
});
