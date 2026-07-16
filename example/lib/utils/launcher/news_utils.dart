import 'dart:convert';

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
    mergedEntries.sort((a, b) => b["version"].compareTo(a["version"]));
    Globals.vanillaNewsResponse = mergedEntries;
  }
}
