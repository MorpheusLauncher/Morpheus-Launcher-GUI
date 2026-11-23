import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';

class NewsUtils {
  static Future<void> getNews() async {
    final oldResponse = await http.get(
      Uri.parse("${Urls.mojangContentURL}/javaPatchNotes.json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    final newResponse = await http.get(
      Uri.parse("${Urls.mojangContentURL}/v2/javaPatchNotes.json"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (oldResponse.statusCode != 200 || newResponse.statusCode != 200) return;

    final oldJson = json.decode(oldResponse.body);
    final newJson = json.decode(newResponse.body);
    final Map<String, dynamic> oldEntriesById = {
      for (var entry in oldJson["entries"]) entry["id"]: entry,
    };
    List<Map<String, dynamic>> mergedEntries = [];
    for (var entry in oldJson["entries"]) {
      mergedEntries.add(entry);
    }
    for (var newEntry in newJson["entries"]) {
      if (!oldEntriesById.containsKey(newEntry["id"])) {
        newEntry["body"] = newEntry["shortText"]?.toString() ?? "";
        newEntry["detailPath"] = "/v2/${newEntry["contentPath"]}";
        mergedEntries.add(newEntry);
      }
    }
    // Le entry del vecchio feed (javaPatchNotes.json) hanno "date": null, e
    // "version" è una stringa libera ("1.21.4", "24w14a", "1.9-pre1"...):
    // ordinarle per stringa mescolava snapshot e release. Si ordina per data
    // di pubblicazione, dalla più recente; quando la entry non ne ha una, si
    // usa la releaseTime del manifest versioni Mojang (stesso id di versione).
    final releaseTimes = await _manifestReleaseTimes();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    DateTime dateOf(Map<String, dynamic> entry) => DateTime.tryParse(entry["date"]?.toString() ?? "") ?? releaseTimes[entry["version"]?.toString()] ?? epoch;

    // Il sort di Dart non è stabile: l'indice originale fa da spareggio così
    // le entry senza alcuna data mantengono l'ordine del feed.
    final indexed = [for (var i = 0; i < mergedEntries.length; i++) (i, mergedEntries[i])];
    indexed.sort((a, b) {
      final byDate = dateOf(b.$2).compareTo(dateOf(a.$2));

      return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
    });
    mergedEntries = [for (final e in indexed) e.$2];

    Globals.vanillaNewsResponse = mergedEntries;
  }

  /// id di versione -> releaseTime dal manifest Mojang. getNews e getVersions
  /// partono in parallelo, quindi il manifest globale può non essere ancora
  /// pronto: in quel caso lo si scarica qui.
  static Future<Map<String, DateTime>> _manifestReleaseTimes() async {
    try {
      var manifest = Globals.vanillaVersionsResponse;
      if (manifest == null) {
        final response = await http.get(Uri.parse(Urls.mojangVersionsURL));
        if (response.statusCode != 200) return {};
        manifest = json.decode(response.body);
      }

      return {
        for (final version in manifest["versions"] as List)
          if (DateTime.tryParse(version["releaseTime"]?.toString() ?? "") != null) version["id"].toString(): DateTime.parse(version["releaseTime"].toString()),
      };
    } catch (e) {
      debugPrint("Unable to load release times for news ordering: $e");

      return {};
    }
  }
}
