import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firebase/admin/admin_firestore_service.dart';
import '../../data/models/section_model.dart';
import '../../data/models/channel_model.dart';
import '../repositories/admin_repository.dart';

final adminFirestoreServiceProvider = Provider<AdminFirestoreService>((ref) {
  return AdminFirestoreService();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(adminFirestoreServiceProvider));
});

final sectionsStreamProvider = StreamProvider<List<SectionModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getSections();
});

final channelsStreamProvider = StreamProvider<List<ChannelModel>>((ref) {
  return ref.watch(adminRepositoryProvider).getChannels();
});
