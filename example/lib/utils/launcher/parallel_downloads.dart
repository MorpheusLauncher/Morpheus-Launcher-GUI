import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

class ModpackDownloadSettings {
  static const _key = 'modpackDownloadConcurrency';
  static const defaultLimit = 10;
  static const maxLimit = 32;
  static int _limit = defaultLimit;

  static int get limit => _limit;

  static void load(SharedPreferences prefs) {
    final saved = prefs.get(_key);
    _limit = saved is int && saved >= 1 && saved <= maxLimit ? saved : defaultLimit;
  }

  static Future<void> save(int value) async {
    RangeError.checkValueInInterval(value, 1, maxLimit);
    _limit = value;
    await (await SharedPreferences.getInstance()).setInt(_key, value);
  }
}

/// Keeps up to [concurrency] downloads active, refilling each available slot.
Future<void> runParallelDownloads<T>(
  List<T> items,
  Future<void> Function(T item) download, {
  int? concurrency,
}) async {
  final limit = concurrency ?? ModpackDownloadSettings.limit;
  if (limit < 1) throw ArgumentError.value(limit, 'concurrency');
  var next = 0;
  Object? error;
  StackTrace? stack;

  Future<void> worker() async {
    while (error == null && next < items.length) {
      final item = items[next++];
      try {
        await download(item);
      } catch (e, s) {
        error ??= e;
        stack ??= s;
      }
    }
  }

  await Future.wait(List.generate(math.min(limit, items.length), (_) => worker()));
  if (error != null) Error.throwWithStackTrace(error!, stack!);
}
