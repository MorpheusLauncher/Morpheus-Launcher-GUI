import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_viewer.dart';

class SkinUtils {
  static Future<Uint8List> loadCroppedSkin() async {
    final rawSkin = await ThreeDimensionalViewer.getImageBytes(
      buildSkinModelImageProvider(),
    );
    final img.Image? original = img.decodeImage(rawSkin);
    if (original == null) return rawSkin;
    final cropped = img.copyCrop(original, x: 8, y: 8, width: 8, height: 8);

    return Uint8List.fromList(img.encodePng(cropped));
  }

  static ImageProvider buildSkinModelImageProvider({Account? account}) {
    account ??= Globals.getAccount();
    if (account == null) {
      return const AssetImage("assets/alex-raw.png");
    }

    final offlineSkin = AssetImage(
      account.isSlimSkin ? "assets/alex-raw.png" : "assets/steve-raw.png",
    );

    String? imageUrl;

    if (account.isPremium) {
      imageUrl = "${Urls.skinURL}/raw/${account.uuid}";
    } else if (account.isElyBy) {
      imageUrl = "${Urls.elybySkinsURL}/skins/${account.username}";
    }

    if (imageUrl != null) {
      try {
        return CachedNetworkImageProvider(imageUrl);
      } catch (_) {
        return offlineSkin;
      }
    }

    return offlineSkin;
  }

  static Future<Uri?> capeUri(Account account, {http.Client? client}) async {
    if (account.isElyBy) {
      if (!RegExp(r'^[A-Za-z0-9_]{1,16}$').hasMatch(account.username)) return null;

      return Uri.parse('${Urls.elybySkinsURL}/cloaks/${Uri.encodeComponent(account.username)}');
    }
    if (!account.isPremium) return null;

    final uuid = account.uuid.replaceAll('-', '');
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(uuid)) return null;
    final httpClient = client ?? http.Client();
    try {
      // The authenticated profile is the authoritative source: the public
      // session profile can keep pointing at a cape texture that is no longer
      // available on the texture CDN.
      if (account.accessToken.isNotEmpty) {
        final activeCape = await _activeCapeFromMinecraftServices(account, httpClient);
        if (activeCape != null) return activeCape;
      }

      final response = await httpClient.get(Uri.https('sessionserver.mojang.com', '/session/minecraft/profile/$uuid')).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw StateError('Mojang profile request failed (${response.statusCode})');
      }

      return capeUriFromMojangProfile(response.body);
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<Uri?> _activeCapeFromMinecraftServices(Account account, http.Client client) async {
    try {
      final response = await client.get(
        Uri.https('api.minecraftservices.com', '/minecraft/profile'),
        headers: {'Authorization': 'Bearer ${account.accessToken}'},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      return capeUriFromMinecraftServicesProfile(response.body);
    } catch (_) {
      // An expired token or a network error must not hide the public profile.
      return null;
    }
  }

  /// Extracts the currently equipped cape from the authenticated
  /// `api.minecraftservices.com/minecraft/profile` response.
  static Uri? capeUriFromMinecraftServicesProfile(String body) {
    try {
      final profile = jsonDecode(body) as Map<String, dynamic>;
      final capes = profile['capes'];
      if (capes is! List) return null;
      for (final cape in capes) {
        if (cape is! Map || cape['state'] != 'ACTIVE') continue;

        return _validatedCapeUri(cape['url']);
      }
    } catch (_) {
      // Missing or malformed profile data means there is no usable cape.
    }
    return null;
  }

  static Uri? capeUriFromMojangProfile(String body) {
    try {
      final profile = jsonDecode(body) as Map<String, dynamic>;
      final properties = profile['properties'] as List<dynamic>? ?? [];
      for (final property in properties) {
        if (property is Map && property['name'] == 'textures' && property['value'] is String) {
          final payload = jsonDecode(utf8.decode(base64.decode(base64.normalize(property['value'] as String)))) as Map<String, dynamic>;
          final textures = payload['textures'];
          final cape = textures is Map ? textures['CAPE'] : null;

          return _validatedCapeUri(cape is Map ? cape['url'] : null);
        }
      }
    } catch (_) {
      // Missing or malformed profile data means there is no usable cape.
    }
    return null;
  }

  static Uri? _validatedCapeUri(Object? url) {
    if (url is! String) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host != 'textures.minecraft.net' || uri.userInfo.isNotEmpty || uri.hasPort || (uri.scheme != 'http' && uri.scheme != 'https')) return null;

    return uri.replace(scheme: 'https');
  }
}
