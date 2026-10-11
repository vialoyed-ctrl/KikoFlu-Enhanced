import '../models/history_record.dart';
import 'history_database.dart';

abstract class PlaybackHistoryStore {
  Future<void> addOrUpdate(HistoryRecord record);

  Future<HistoryRecord?> getByWorkId(int workId);
}

class DatabasePlaybackHistoryStore implements PlaybackHistoryStore {
  const DatabasePlaybackHistoryStore();

  @override
  Future<void> addOrUpdate(HistoryRecord record) {
    return HistoryDatabase.instance.addOrUpdate(record);
  }

  @override
  Future<HistoryRecord?> getByWorkId(int workId) {
    return HistoryDatabase.instance.getHistoryByWorkId(workId);
  }
}
