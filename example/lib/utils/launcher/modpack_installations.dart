import 'dart:async';

import 'package:flutter/foundation.dart';

class InstallationCancelled implements Exception {
  const InstallationCancelled();
}

class InstallationCancellation {
  final Completer<void> _cancelled = Completer<void>();
  bool _committing = false;

  bool get isCancelled => _cancelled.isCompleted;

  bool get canCancel => !_committing && !isCancelled;

  void cancel() {
    if (canCancel) _cancelled.complete();
  }

  void check() {
    if (isCancelled) throw const InstallationCancelled();
  }

  void beginCommit() {
    check();
    _committing = true;
  }

  Future<T> wait<T>(Future<T> operation) {
    check();
    return Future.any([operation, _cancelled.future.then<T>((_) => throw const InstallationCancelled())]);
  }
}

class ModpackInstallation {
  final String key;
  final String provider;
  final String title;
  final String iconUrl;
  double progress = 0;
  String status = '';
  Object? error;
  final cancellation = InstallationCancellation();

  ModpackInstallation({required this.key, required this.provider, required this.title, required this.iconUrl});
}

/// Lives independently of the detail route so downloads survive navigation.
class ModpackInstallations extends ChangeNotifier {
  static final instance = ModpackInstallations();
  final Map<String, ModpackInstallation> _tasks = {};

  Iterable<ModpackInstallation> get tasks => List.unmodifiable(_tasks.values);

  ModpackInstallation? operator [](String key) => _tasks[key];

  Future<void> start({
    required String key,
    required String provider,
    required String title,
    required String iconUrl,
    required Future<void> Function(void Function(double), void Function(String), InstallationCancellation) install,
  }) async {
    if (_tasks[key] != null && _tasks[key]!.error == null) throw StateError('Installation already in progress');
    final task = ModpackInstallation(key: key, provider: provider, title: title, iconUrl: iconUrl);
    _tasks[key] = task;
    notifyListeners();
    var lastNotification = DateTime.fromMillisecondsSinceEpoch(0);
    var lastPercent = -1;
    void notifyProgress() {
      final now = DateTime.now();
      final percent = (task.progress * 100).floor();
      if (percent != lastPercent || now.difference(lastNotification).inMilliseconds >= 200) {
        lastPercent = percent;
        lastNotification = now;
        notifyListeners();
      }
    }

    try {
      await install((value) {
        task.progress = value.clamp(0.0, 1.0);
        notifyProgress();
      }, (value) {
        task.status = value;
        notifyProgress();
      }, task.cancellation);
      _tasks.remove(key);
      notifyListeners();
    } on InstallationCancelled {
      _tasks.remove(key);
      notifyListeners();
      rethrow;
    } catch (e) {
      task.error = e;
      notifyListeners();
      rethrow;
    }
  }

  void cancel(String key) {
    final task = _tasks[key];
    if (task != null && task.error == null && task.cancellation.canCancel) {
      task.cancellation.cancel();
      notifyListeners();
    }
  }

  void dismiss(String key) {
    if (_tasks[key]?.error != null) {
      _tasks.remove(key);
      notifyListeners();
    }
  }
}
