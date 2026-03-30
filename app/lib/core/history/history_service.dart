import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'history_entry.dart';

class HistoryService {
  Directory? _historyDir;
  File? _indexFile;

  Future<void> _ensureInitialized() async {
    if (_historyDir != null) return;
    final appDir = await getApplicationDocumentsDirectory();
    _historyDir = Directory('${appDir.path}/history');
    if (!await _historyDir!.exists()) {
      await _historyDir!.create(recursive: true);
    }
    _indexFile = File('${_historyDir!.path}/history.json');
  }

  Future<List<HistoryEntry>> getAll() async {
    await _ensureInitialized();
    if (!await _indexFile!.exists()) return [];

    try {
      final content = await _indexFile!.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[HistoryService] Error reading history: $e');
      return [];
    }
  }

  Future<HistoryEntry> add({
    required String originalName,
    required HistoryType type,
    required Uint8List resultBytes,
    required int originalSizeBytes,
  }) async {
    await _ensureInitialized();

    final id = '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
    final ext = type == HistoryType.pdf ? 'pdf' : 'png';
    final resultFile = File('${_historyDir!.path}/$id.$ext');
    await resultFile.writeAsBytes(resultBytes);

    final entry = HistoryEntry(
      id: id,
      originalName: originalName,
      resultPath: resultFile.path,
      type: type,
      createdAt: DateTime.now(),
      originalSizeBytes: originalSizeBytes,
      resultSizeBytes: resultBytes.length,
    );

    final entries = await getAll();
    entries.insert(0, entry);
    await _writeIndex(entries);

    return entry;
  }

  Future<Uint8List?> getResultBytes(HistoryEntry entry) async {
    final file = File(entry.resultPath);
    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }

  Future<void> remove(String id) async {
    await _ensureInitialized();
    final entries = await getAll();
    final entry = entries.where((e) => e.id == id).firstOrNull;

    if (entry != null) {
      final file = File(entry.resultPath);
      if (await file.exists()) await file.delete();
    }

    entries.removeWhere((e) => e.id == id);
    await _writeIndex(entries);
  }

  Future<void> clear() async {
    await _ensureInitialized();
    final entries = await getAll();

    for (final entry in entries) {
      final file = File(entry.resultPath);
      if (await file.exists()) await file.delete();
    }

    await _writeIndex([]);
  }

  Map<HistoryType, List<HistoryEntry>> groupByType(List<HistoryEntry> entries) {
    final grouped = <HistoryType, List<HistoryEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.type, () => []).add(entry);
    }
    return grouped;
  }

  Future<void> _writeIndex(List<HistoryEntry> entries) async {
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    await _indexFile!.writeAsString(json);
  }
}
