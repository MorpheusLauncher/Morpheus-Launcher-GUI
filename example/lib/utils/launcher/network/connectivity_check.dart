import 'dart:async';
import 'dart:io';

typedef ConnectivityProbe = Future<bool> Function(String address, Duration timeout);

class ConnectivityCheck {
  static const addresses = ['1.1.1.1', '8.8.8.8'];

  static Future<bool> _connect(String address, Duration timeout) async {
    try {
      final socket = await Socket.connect(address, 443, timeout: timeout);
      socket.destroy();

      return true;
    } catch (_) {
      return false;
    }
  }

  /// A failed probe does not prove that the internet is unavailable.
  static Future<bool> check({
    ConnectivityProbe? probe,
    Duration timeout = const Duration(seconds: 3),
  }) {
    final result = Completer<bool>();
    var remaining = addresses.length;
    for (final address in addresses) {
      Future.sync(() => (probe ?? _connect)(address, timeout)).timeout(timeout, onTimeout: () => false).catchError((_) => false).then((success) {
        remaining--;
        if (!result.isCompleted && (success || remaining == 0)) {
          result.complete(success);
        }
      });
    }

    return result.future;
  }
}
