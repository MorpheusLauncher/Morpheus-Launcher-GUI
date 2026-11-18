import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_utils.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_viewer.dart';

void main() {
  Account account({required bool slim}) => Account(
        username: slim ? 'Alex' : 'Steve',
        uuid: slim ? 'alex' : 'steve',
        accessToken: '',
        refreshToken: '',
        isPremium: false,
        isSlimSkin: slim,
        isElyBy: false,
      );

  test('Mojang cape URLs are extracted safely', () {
    String profile(String url) => jsonEncode({
          'properties': [
            {
              'name': 'textures',
              'value': base64.encode(utf8.encode(jsonEncode({
                'textures': {
                  'CAPE': {'url': url}
                }
              }))),
            }
          ]
        });
    expect(
      SkinUtils.capeUriFromMojangProfile(profile('http://textures.minecraft.net/texture/abc')).toString(),
      'https://textures.minecraft.net/texture/abc',
    );
    expect(SkinUtils.capeUriFromMojangProfile(profile('https://example.com/cape.png')), isNull);
    expect(SkinUtils.capeUriFromMojangProfile('invalid'), isNull);
    expect(SkinUtils.capeUriFromMojangProfile('{"properties":[]}'), isNull);
  });

  test('Mojang cape lookup reports errors instead of hiding them', () async {
    final premium = account(slim: false)
      ..isPremium = true
      ..uuid = '853c80ef3c3749fdaa49938b674adae6';
    final client = MockClient((request) async => http.Response('', 429));
    await expectLater(SkinUtils.capeUri(premium, client: client), throwsStateError);
    client.close();
  });

  test('Minecraft services profile exposes only the active cape', () {
    String profile(List<Map<String, dynamic>> capes) => jsonEncode({'capes': capes});
    expect(
      SkinUtils.capeUriFromMinecraftServicesProfile(profile([
        {'state': 'INACTIVE', 'url': 'http://textures.minecraft.net/texture/old'},
        {'state': 'ACTIVE', 'url': 'http://textures.minecraft.net/texture/active'},
      ])),
      Uri.parse('https://textures.minecraft.net/texture/active'),
    );
    expect(
      SkinUtils.capeUriFromMinecraftServicesProfile(profile([
        {'state': 'ACTIVE', 'url': 'https://example.com/cape.png'},
      ])),
      isNull,
    );
    expect(SkinUtils.capeUriFromMinecraftServicesProfile('invalid'), isNull);
    expect(SkinUtils.capeUriFromMinecraftServicesProfile('{}'), isNull);
  });

  test('the authenticated profile supplies the equipped cape first', () async {
    final premium = account(slim: false)
      ..isPremium = true
      ..accessToken = 'token'
      ..uuid = '853c80ef-3c37-49fd-aa49-938b674adae6';
    final payload = base64.encode(utf8.encode(jsonEncode({
      'textures': {
        'CAPE': {'url': 'http://textures.minecraft.net/texture/public'}
      }
    })));
    final client = MockClient((request) async {
      if (request.url.host == 'api.minecraftservices.com') {
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(
            jsonEncode({
              'capes': [
                {'state': 'ACTIVE', 'url': 'http://textures.minecraft.net/texture/active'},
              ]
            }),
            200);
      }
      if (request.url.host == 'sessionserver.mojang.com') {
        return http.Response(
            jsonEncode({
              'properties': [
                {'name': 'textures', 'value': payload}
              ]
            }),
            200);
      }
      return http.Response('', 404);
    });
    expect(await SkinUtils.capeUri(premium, client: client), Uri.parse('https://textures.minecraft.net/texture/active'));
    client.close();
  });

  test('an expired token falls back to the public profile', () async {
    final premium = account(slim: false)
      ..isPremium = true
      ..accessToken = 'expired'
      ..uuid = '853c80ef3c3749fdaa49938b674adae6';
    final payload = base64.encode(utf8.encode(jsonEncode({
      'textures': {
        'CAPE': {'url': 'http://textures.minecraft.net/texture/public'}
      }
    })));
    final client = MockClient((request) async {
      if (request.url.host == 'api.minecraftservices.com') {
        return http.Response('', 401);
      }
      return http.Response(
          jsonEncode({
            'properties': [
              {'name': 'textures', 'value': payload}
            ]
          }),
          200);
    });
    expect(await SkinUtils.capeUri(premium, client: client), Uri.parse('https://textures.minecraft.net/texture/public'));
    client.close();
  });

  test('Mojang cape lookup resolves the active cape', () async {
    final premium = account(slim: false)
      ..isPremium = true
      ..uuid = '853c80ef-3c37-49fd-aa49-938b674adae6';
    final payload = base64.encode(utf8.encode(jsonEncode({
      'textures': {
        'CAPE': {'url': 'http://textures.minecraft.net/texture/test'}
      }
    })));
    final client = MockClient((request) async {
      expect(request.url.host, 'sessionserver.mojang.com');
      expect(request.url.path, '/session/minecraft/profile/853c80ef3c3749fdaa49938b674adae6');
      return http.Response(
          jsonEncode({
            'properties': [
              {'name': 'textures', 'value': payload}
            ]
          }),
          200);
    });
    expect(await SkinUtils.capeUri(premium, client: client), Uri.parse('https://textures.minecraft.net/texture/test'));
    client.close();
  });

  testWidgets('loads, animates and supports camera interaction for offline skins', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MinecraftSkinViewer(account: account(slim: false))));
    for (var i = 0; i < 20 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MinecraftSkinViewer),
        matching: find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter != null),
      ),
      findsOneWidget,
    );
    final painter = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byType(MinecraftSkinViewer),
            matching: find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter != null),
          ),
        )
        .painter!;
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(180, 290));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(180, 290);
    final data = await tester.runAsync(() => image.toByteData());
    expect(data, isNotNull);
    final rgba = data!.buffer.asUint8List();
    var visiblePixels = 0;
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] > 0) visiblePixels++;
    }
    expect(visiblePixels, greaterThan(1000));
    final colors = <String>{};
    for (var i = 0; i < rgba.length; i += 4) {
      if (rgba[i + 3] > 0) colors.add('${rgba[i]},${rgba[i + 1]},${rgba[i + 2]}');
    }
    expect(colors.length, greaterThan(10));
    image.dispose();
    picture.dispose();

    var paints = 0;
    void countPaint() => paints++;
    painter.addListener(countPaint);
    await tester.pump(const Duration(microseconds: 16667));
    paints = 0;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(microseconds: 16667));
    }
    expect(paints, 6, reason: 'the viewer should repaint at each 60 Hz frame');
    painter.removeListener(countPaint);
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(MinecraftSkinViewer), const Offset(40, 20));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(MaterialApp(home: MinecraftSkinViewer(account: account(slim: true))));
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('loads a cape and renders it from behind', (tester) async {
    final cape = img.Image(width: 64, height: 32, numChannels: 4);
    for (var y = 1; y < 17; y++) {
      for (var x = 1; x < 6; x++) {
        cape.setPixelRgba(x, y, 255, 0, 255, 255);
      }
      for (var x = 6; x < 11; x++) {
        cape.setPixelRgba(x, y, 0, 255, 255, 255);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(cape));
    await tester.pumpWidget(MaterialApp(
      home: MinecraftSkinViewer(
        account: account(slim: false),
        capeLoader: (_) async => bytes,
      ),
    ));
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 50));
    await tester.drag(find.byType(MinecraftSkinViewer), const Offset(210, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final painter = tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(MinecraftSkinViewer),
          matching: find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter != null),
        ))
        .painter!;
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(180, 290));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(180, 290);
    final data = await tester.runAsync(() => image.toByteData());
    final rgba = data!.buffer.asUint8List();
    var magenta = 0;
    var cyan = 0;
    var magentaX = 0;
    var cyanX = 0;
    for (var i = 0; i < rgba.length; i += 4) {
      if (rgba[i] > 150 && rgba[i + 1] < 50 && rgba[i + 2] > 150 && rgba[i + 3] > 0) {
        magenta++;
        magentaX += (i ~/ 4) % 180;
      }
      if (rgba[i] < 50 && rgba[i + 1] > 150 && rgba[i + 2] > 150 && rgba[i + 3] > 0) {
        cyan++;
        cyanX += (i ~/ 4) % 180;
      }
    }
    expect(magenta, greaterThan(100), reason: 'the loaded cape must be visible on the back');
    expect(cyan, greaterThan(100));
    expect(magentaX / magenta, lessThan(cyanX / cyan), reason: 'the cape texture must not be mirrored');
    image.dispose();
    picture.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('loads a premium cape through Mojang and paints it', (tester) async {
    final cape = img.Image(width: 64, height: 32, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 64; x++) {
        cape.setPixelRgba(x, y, 255, 0, 255, 255);
      }
    }
    final capeBytes = Uint8List.fromList(img.encodePng(cape));
    final premium = account(slim: false)
      ..isPremium = true
      ..accessToken = 'token'
      ..uuid = '853c80ef3c3749fdaa49938b674adae6';
    final requests = <Uri>[];
    await tester.pumpWidget(MaterialApp(
      home: MinecraftSkinViewer(
        account: premium,
        httpClientFactory: () => MockClient((request) async {
          requests.add(request.url);
          if (request.url.host == 'api.minecraftservices.com') {
            return http.Response(
                jsonEncode({
                  'capes': [
                    {'state': 'ACTIVE', 'url': 'http://textures.minecraft.net/texture/test'},
                  ]
                }),
                200);
          }
          if (request.url.host == 'textures.minecraft.net') {
            return http.Response.bytes(capeBytes, 200);
          }
          return http.Response('', 404);
        }),
      ),
    ));
    for (var i = 0; i < 80; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
      if (requests.any((uri) => uri.host == 'textures.minecraft.net')) break;
    }
    await tester.pump(const Duration(milliseconds: 50));
    expect(requests.map((uri) => uri.host), containsAll(['api.minecraftservices.com', 'textures.minecraft.net']));
    await tester.drag(find.byType(MinecraftSkinViewer), const Offset(210, 0));
    await tester.pump(const Duration(milliseconds: 16));
    final painter = tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(MinecraftSkinViewer),
          matching: find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter != null),
        ))
        .painter!;
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(180, 290));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(180, 290);
    final rgba = (await tester.runAsync(() => image.toByteData()))!.buffer.asUint8List();
    var magenta = 0;
    for (var i = 0; i < rgba.length; i += 4) {
      if (rgba[i] > 150 && rgba[i + 1] < 50 && rgba[i + 2] > 150 && rgba[i + 3] > 0) magenta++;
    }
    expect(magenta, greaterThan(100));
    image.dispose();
    picture.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
