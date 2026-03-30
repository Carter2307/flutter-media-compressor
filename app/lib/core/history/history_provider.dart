import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_entry.dart';
import 'history_service.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends AsyncNotifier<List<HistoryEntry>> {
  HistoryService get _service => ref.read(historyServiceProvider);

  @override
  Future<List<HistoryEntry>> build() => _service.getAll();

  Future<void> add({
    required String originalName,
    required HistoryType type,
    required Uint8List resultBytes,
    required int originalSizeBytes,
  }) async {
    await _service.add(
      originalName: originalName,
      type: type,
      resultBytes: resultBytes,
      originalSizeBytes: originalSizeBytes,
    );
    state = AsyncData(await _service.getAll());
  }

  Future<void> remove(String id) async {
    await _service.remove(id);
    state = AsyncData(await _service.getAll());
  }

  Future<void> clear() async {
    await _service.clear();
    state = const AsyncData([]);
  }

  Future<Uint8List?> getResultBytes(HistoryEntry entry) {
    return _service.getResultBytes(entry);
  }

  Map<HistoryType, List<HistoryEntry>> get grouped {
    final entries = state.valueOrNull ?? [];
    return _service.groupByType(entries);
  }
}
