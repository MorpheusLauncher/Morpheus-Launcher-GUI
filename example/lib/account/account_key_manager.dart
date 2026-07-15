library account_key_manager;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyStorageKey = 'morpheus_launcher_file_key_v1';

// v4.2.1 — costruttore senza parametri, funziona su win/mac/linux
const _storage = FlutterSecureStorage();

Future<Uint8List> loadOrCreateFileKey() async {
  try {
    final existing = await _storage.read(key: _keyStorageKey);
    if (existing != null) {
      return base64.decode(existing);
    }
  } catch (e) {
    debugPrint('Key read failed, generating new key: $e');
  }

  final key = _generateSecureKey(32);
  await _storage.write(key: _keyStorageKey, value: base64.encode(key));
  return key;
}

Future<void> deleteFileKey() async {
  await _storage.delete(key: _keyStorageKey);
}

Future<bool> isSecureStorageAvailable() async {
  try {
    await _storage.write(key: '__probe__', value: '1');
    await _storage.delete(key: '__probe__');
    return true;
  } catch (_) {
    return false;
  }
}

Uint8List _generateSecureKey(int bytes) {
  final rng = Random.secure();
  return Uint8List.fromList(List.generate(bytes, (_) => rng.nextInt(256)));
}
