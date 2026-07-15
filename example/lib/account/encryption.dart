library account_file;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:morpheus_launcher_gui/account/account_key_manager.dart';
import 'package:morpheus_launcher_gui/account/account_utils.dart';

// ---------------------------------------------------------------------------
// AES-GCM con IV casuale per ogni operazione
// ---------------------------------------------------------------------------

String _aesGcmEncrypt(String plaintext, Uint8List key) {
  if (plaintext.isEmpty) return '';
  final iv = enc.IV(Uint8List.fromList(
    List.generate(12, (_) => Random.secure().nextInt(256)),
  ));
  final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
  final encrypted = encrypter.encrypt(plaintext, iv: iv);
  final out = Uint8List(12 + encrypted.bytes.length);
  out.setRange(0, 12, iv.bytes);
  out.setRange(12, out.length, encrypted.bytes);
  return base64.encode(out);
}

String _aesGcmDecrypt(String b64, Uint8List key) {
  if (b64.isEmpty) return '';
  final combined = base64.decode(b64);
  if (combined.length < 12) throw FormatException('Ciphertext too short');
  final iv = enc.IV(combined.sublist(0, 12));
  final encrypter = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.gcm));
  return encrypter.decrypt(enc.Encrypted(combined.sublist(12)), iv: iv);
}

// ---------------------------------------------------------------------------
// Chiave token derivata dalla chiave file (separata)
// ---------------------------------------------------------------------------

Uint8List _deriveTokenKey(Uint8List fileKey) {
  final input = [...fileKey, ...utf8.encode('morpheus-token-key-v1')];
  return Uint8List.fromList(sha256.convert(input).bytes);
}

// ---------------------------------------------------------------------------
// Cifratura file intero
// ---------------------------------------------------------------------------

void _writeEncryptedFile(File file, String jsonString, Uint8List fileKey) {
  final iv = Uint8List.fromList(
    List.generate(12, (_) => Random.secure().nextInt(256)),
  );
  final encrypter = enc.Encrypter(enc.AES(enc.Key(fileKey), mode: enc.AESMode.gcm));
  final encrypted = encrypter.encrypt(jsonString, iv: enc.IV(iv));
  final out = Uint8List(12 + encrypted.bytes.length);
  out.setRange(0, 12, iv);
  out.setRange(12, out.length, encrypted.bytes);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(out);
}

String _readEncryptedFile(File file, Uint8List fileKey) {
  final bytes = file.readAsBytesSync();
  if (bytes.length < 12) throw FormatException('File too short');
  final iv = enc.IV(bytes.sublist(0, 12));
  final encrypter = enc.Encrypter(enc.AES(enc.Key(fileKey), mode: enc.AESMode.gcm));
  return encrypter.decrypt(enc.Encrypted(bytes.sublist(12)), iv: iv);
}

// ---------------------------------------------------------------------------
// API pubblica — ora async
// ---------------------------------------------------------------------------

Future<void> saveAccountListToJson(
  List<Account> accountList,
  String filePath,
) async {
  final fileKey = await loadOrCreateFileKey();
  final tokenKey = _deriveTokenKey(fileKey);

  final json = const JsonEncoder.withIndent('  ').convert(
    accountList.map((a) {
      final plain = a.toJson();
      plain['accessToken'] = _aesGcmEncrypt(plain['accessToken'] as String, tokenKey);
      plain['refreshToken'] = _aesGcmEncrypt(plain['refreshToken'] as String, tokenKey);
      return plain;
    }).toList(),
  );

  _writeEncryptedFile(File(filePath), json, fileKey);
}

/// Restituisce null se la decifratura fallisce, [] se il file non esiste.
Future<List<Account>?> readAccountListFromJson(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) return [];

  try {
    final fileKey = await loadOrCreateFileKey();
    final tokenKey = _deriveTokenKey(fileKey);

    final jsonString = _readEncryptedFile(file, fileKey);

    return (jsonDecode(jsonString) as List).map((j) {
      final copy = Map<String, dynamic>.from(j as Map<String, dynamic>);
      try {
        copy['accessToken'] = _aesGcmDecrypt(copy['accessToken'] as String, tokenKey);
        copy['refreshToken'] = _aesGcmDecrypt(copy['refreshToken'] as String, tokenKey);
      } catch (e) {
        debugPrint("Token decrypt failed for '${copy['username']}': $e");
        copy['accessToken'] = '';
        copy['refreshToken'] = '';
      }
      return Account.fromJson(copy);
    }).toList();
  } catch (e) {
    debugPrint('Account file read failed: $e');
    await saveAccountListToJson([], filePath);
    return null;
  }
}
