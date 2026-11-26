import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';

/// Normalized browser cards use the Modrinth search field names, while
/// retaining the original data for the source-specific details screen.
class ModpackSearchResult {
  final List<Map<String, dynamic>> packs;
  final int total;

  const ModpackSearchResult({required this.packs, required this.total});
}

abstract class ModpackBrowserSource {
  const ModpackBrowserSource();

  int get minimumQueryLength => 0;

  Future<ModpackSearchResult> search(String query, {required int limit, required int offset});
}

class ModrinthBrowserSource extends ModpackBrowserSource {
  final http.Client? client;

  const ModrinthBrowserSource({this.client});

  @override
  Future<ModpackSearchResult> search(String query, {required int limit, required int offset}) async {
    final uri = Uri.parse('${Urls.modrinthApiURL}/search').replace(queryParameters: {
      'query': query,
      'facets': '[["project_type:modpack"]]',
      'limit': '$limit',
      'offset': '$offset',
    });
    final response = client == null ? await http.get(uri) : await client!.get(uri);
    if (response.statusCode != 200) throw Exception('Modrinth search failed: ${response.statusCode}');
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final packs = (data['hits'] as List).cast<Map<String, dynamic>>();

    return ModpackSearchResult(packs: packs, total: data['total_hits'] as int? ?? packs.length);
  }
}

/// FTB returns pack IDs separately from their details. Search results also
/// include CurseForge IDs, which belong to a different provider.
class FtbBrowserSource extends ModpackBrowserSource {
  static const apiUrl = '${Urls.ftbApiURL}/modpack';
  final http.Client? client;

  const FtbBrowserSource({this.client});

  @override
  int get minimumQueryLength => 3;

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = client == null ? await http.get(uri) : await client!.get(uri);
    if (response.statusCode != 200) throw Exception('FTB request failed: ${response.statusCode}');
    final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (data['status'] == 'error') throw Exception('FTB: ${data['message']}');

    return data;
  }

  @override
  Future<ModpackSearchResult> search(String query, {required int limit, required int offset}) async {
    // FTB rejects searches shorter than three characters.
    if (query.isNotEmpty && query.runes.length < 3) {
      return const ModpackSearchResult(packs: [], total: 0);
    }
    final uri = query.isEmpty ? Uri.parse('$apiUrl/all') : Uri.parse('$apiUrl/search/50').replace(queryParameters: {'term': query});
    final data = await _get(uri);
    final ids = (data['packs'] as List).whereType<int>().toSet().toList();
    final start = offset.clamp(0, ids.length);
    final end = (start + limit).clamp(start, ids.length);
    final results = await Future.wait(ids.sublist(start, end).map((id) async {
      final pack = await _get(Uri.parse('$apiUrl/$id'));
      final art = (pack['art'] as List? ?? []).whereType<Map>().where((a) => a['type'] == 'square');
      final authors = (pack['authors'] as List? ?? []).whereType<Map>();

      return <String, dynamic>{
        ...pack,
        '_full_description': pack['description'] ?? '',
        'project_id': '$id',
        'title': pack['name'] ?? '',
        'description': pack['synopsis'] ?? '',
        'icon_url': art.isEmpty ? '' : art.first['url'] ?? '',
        'author': authors.isEmpty ? '' : authors.first['name'] ?? '',
        'downloads': pack['installs'] ?? 0,
        'categories': (pack['tags'] as List? ?? []).whereType<Map>().map((tag) => tag['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList(),
        'date_modified': pack['updated'] is num ? DateTime.fromMillisecondsSinceEpoch((pack['updated'] as num).toInt() * 1000, isUtc: true).toIso8601String() : null,
      };
    }));

    return ModpackSearchResult(packs: results, total: ids.length);
  }
}
