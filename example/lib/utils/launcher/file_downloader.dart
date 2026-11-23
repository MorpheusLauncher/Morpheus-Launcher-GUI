import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/utils/launcher/modpack_installations.dart';
import 'package:path/path.dart' as p;

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

final _random = Random.secure();

class DownloadBatch {
  final _pending = <File, ({File destination, int? size, String? sha1})>{};

  Future<void> verify(InstallationCancellation? cancellation, void Function(double) progress) async {
    final total = _pending.length;
    for (final file in _pending.keys.toList()) {
      cancellation?.check();
      final entry = _pending[file]!;
      if (entry.size != null && await file.length() != entry.size) {
        throw FormatException('Invalid size: ${entry.destination.path}');
      }
      if (entry.sha1 != null) {
        final digest = _DigestSink();
        final hash = sha1.startChunkedConversion(digest);
        await for (final chunk in file.openRead()) {
          cancellation?.check();
          hash.add(chunk);
        }
        hash.close();
        if (digest.value.toString() != entry.sha1!.toLowerCase()) {
          throw FormatException('Invalid SHA-1: ${entry.destination.path}');
        }
      }
      cancellation?.check();
      await file.rename(entry.destination.path);
      _pending.remove(file);
      progress((total - _pending.length) / total);
    }
  }

  Future<void> discardPending() async {
    for (final file in _pending.keys) {
      await file.delete();
    }
    _pending.clear();
  }

  Future<void> downloadFile({
    required http.Client client,
    required Uri url,
    required File destination,
    InstallationCancellation? cancellation,
    int? expectedSize,
    String? expectedSha1,
  }) async {
    cancellation?.check();
    final request = client.send(http.Request('GET', url));
    final response = await (cancellation?.wait(request) ?? request);
    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw HttpException('HTTP ${response.statusCode}: $url');
    }
    cancellation?.check();
    await destination.parent.create(recursive: true);
    final nonce = List.generate(4, (_) => _random.nextInt(1 << 30).toRadixString(36)).join('-');
    final tempFile = File(p.join(destination.parent.path, '.download-$nonce.part'));
    await tempFile.create(exclusive: true);
    var staged = false;
    RandomAccessFile? output;
    StreamIterator<List<int>>? iterator;
    try {
      output = await tempFile.open(mode: FileMode.write);
      iterator = StreamIterator(response.stream);
      const writeSize = 64 * 1024;
      final pending = BytesBuilder();
      while (true) {
        final next = iterator.moveNext();
        if (!await (cancellation?.wait(next) ?? next)) break;
        cancellation?.check();
        final bytes = iterator.current;
        if (pending.length + bytes.length >= writeSize && pending.isNotEmpty) {
          await output.writeFrom(pending.takeBytes());
        }
        if (bytes.length >= writeSize) {
          await output.writeFrom(bytes);
        } else {
          pending.add(bytes);
        }
      }
      if (pending.isNotEmpty) await output.writeFrom(pending.takeBytes());
      await output.close();
      output = null;
      cancellation?.check();
      _pending[tempFile] = (destination: destination, size: expectedSize, sha1: expectedSha1);
      staged = true;
    } finally {
      await iterator?.cancel();
      await output?.close();
      if (!staged) await tempFile.delete();
    }
  }
}
