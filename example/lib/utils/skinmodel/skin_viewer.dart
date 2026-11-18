import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_utils.dart';

/// An animated Minecraft skin preview drawn entirely with Flutter's canvas.
class MinecraftSkinViewer extends StatefulWidget {
  const MinecraftSkinViewer({super.key, required this.account, this.capeLoader, this.httpClientFactory});

  final Account account;

  /// Optional texture loader, useful for alternate cape providers.
  final Future<Uint8List?> Function(Account account)? capeLoader;

  /// Optional HTTP client factory for custom networking and tests.
  final http.Client Function()? httpClientFactory;

  @override
  State<MinecraftSkinViewer> createState() => _MinecraftSkinViewerState();
}

class _MinecraftSkinViewerState extends State<MinecraftSkinViewer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _animationTime = ValueNotifier(0);
  late Future<_SkinTextures> _textures;
  double _yaw = 0.45;
  double _pitch = 0.35;
  double _zoom = 1;
  int _loadGeneration = 0;
  _SkinTextures? _pendingCapeTextures;
  double _elapsedOffset = 0;

  @override
  void initState() {
    super.initState();
    _textures = _loadTextures();
    _ticker = createTicker((elapsed) {
      _animationTime.value = _elapsedOffset + elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled && !MediaQuery.disableAnimationsOf(context)) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _elapsedOffset = _animationTime.value;
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(covariant MinecraftSkinViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.capeLoader != widget.capeLoader ||
        oldWidget.httpClientFactory != widget.httpClientFactory ||
        oldWidget.account.uuid != widget.account.uuid ||
        oldWidget.account.username != widget.account.username ||
        oldWidget.account.isSlimSkin != widget.account.isSlimSkin ||
        oldWidget.account.isPremium != widget.account.isPremium ||
        oldWidget.account.isElyBy != widget.account.isElyBy) {
      _textures = _loadTextures();
      _yaw = 0.35;
      _pitch = -0.13;
      _zoom = 1;
    }
  }

  Future<_SkinTextures> _loadTextures() async {
    final generation = ++_loadGeneration;
    final account = widget.account;
    final skinProvider = SkinUtils.buildSkinModelImageProvider(account: account);
    final fallback = AssetImage(account.isSlimSkin ? 'assets/alex-raw.png' : 'assets/steve-raw.png');
    img.Image skin;
    try {
      if (widget.httpClientFactory == null) {
        skin = await _loadImage(skinProvider);
      } else {
        final client = widget.httpClientFactory!();
        try {
          skin = await _loadImage(skinProvider, client: client);
        } finally {
          client.close();
        }
      }
    } catch (_) {
      skin = await _loadImage(fallback);
    }

    final textures = _SkinTextures(skin);
    if (mounted && generation == _loadGeneration) {
      _pendingCapeTextures = textures;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && generation == _loadGeneration && identical(_pendingCapeTextures, textures)) {
          _pendingCapeTextures = null;
          unawaited(_loadCape(account, textures, generation));
        }
      });
    }

    return textures;
  }

  Future<void> _loadCape(Account account, _SkinTextures textures, int generation) async {
    try {
      final loader = widget.capeLoader;
      final img.Image cape;
      if (loader != null) {
        final bytes = await loader(account);
        if (bytes == null) return;
        cape = _decodeTexture(bytes, cape: true);
      } else {
        final client = widget.httpClientFactory?.call() ?? http.Client();
        try {
          final uri = await SkinUtils.capeUri(account, client: client);
          if (uri == null) {
            if (account.isPremium || account.isElyBy) {
              debugPrint('MinecraftSkinViewer: no official or Ely.by cape is available for this account');
            }

            return;
          }
          if (!mounted || generation != _loadGeneration) return;
          cape = await _loadImage(NetworkImage(uri.toString()), cape: true, client: client);
        } finally {
          client.close();
        }
      }
      if (!mounted || generation != _loadGeneration) return;
      setState(() => textures.cape = cape);
    } catch (error) {
      debugPrint('MinecraftSkinViewer: cape load failed: $error');
      // Missing or unavailable capes must not prevent the skin from loading.
    }
  }

  static Future<img.Image> _loadImage(ImageProvider provider, {bool cape = false, http.Client? client}) async {
    final Uint8List bytes;
    if (provider is AssetImage) {
      final data = await rootBundle.load(provider.assetName);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else if (provider is NetworkImage || (provider is CachedNetworkImageProvider && client != null)) {
      final httpClient = client ?? http.Client();
      try {
        final url = provider is NetworkImage ? provider.url : (provider as CachedNetworkImageProvider).url;
        final response = await httpClient.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) throw StateError('Texture unavailable (${response.statusCode})');
        bytes = response.bodyBytes;
      } finally {
        if (client == null) httpClient.close();
      }
    } else {
      bytes = await ThreeDimensionalViewer.getImageBytes(provider);
    }

    return _decodeTexture(bytes, cape: cape);
  }

  static img.Image _decodeTexture(Uint8List bytes, {bool cape = false}) {
    if (bytes.length > 4 * 1024 * 1024) throw const FormatException('Minecraft texture is too large');
    final image = img.decodeImage(bytes);
    if (image == null || image.width < 64 || image.width % 64 != 0 || (cape ? image.height * 2 != image.width : image.height != image.width && image.height * 2 != image.width)) {
      throw const FormatException('Invalid Minecraft texture');
    }

    return image;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _animationTime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 290,
      child: FutureBuilder<_SkinTextures>(
        future: _textures,
        builder: (context, snapshot) {
          final textures = snapshot.data;
          if (textures == null) {
            return Center(child: snapshot.hasError ? const Icon(Icons.person_outline) : const CircularProgressIndicator());
          }

          return RepaintBoundary(
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    setState(() => _zoom = (_zoom * math.exp(-event.scrollDelta.dy * 0.0015)).clamp(0.65, 1.7));
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      _yaw += details.delta.dx * 0.015;
                      _pitch = (_pitch + details.delta.dy * 0.015).clamp(-1.3, 1.3);
                    });
                  },
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _SkinPainter(
                        textures: textures,
                        slim: widget.account.isSlimSkin,
                        animationTime: _animationTime,
                        yaw: _yaw,
                        pitch: _pitch,
                        zoom: _zoom,
                        cape: textures.cape,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SkinTextures {
  _SkinTextures(img.Image source) : skin = source.width > 64 ? img.copyResize(source, width: 64, height: (source.height * 64 / source.width).round(), interpolation: img.Interpolation.nearest) : source;
  final img.Image skin;
  img.Image? _cape;

  img.Image? get cape => _cape;

  set cape(img.Image? value) {
    _cape = value != null && value.width > 64 ? img.copyResize(value, width: 64, height: (value.height * 64 / value.width).round(), interpolation: img.Interpolation.nearest) : value;
  }
}

class _Point3 {
  const _Point3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _Face {
  _Face(this.points, this.color, this.depth);

  final List<Offset> points;
  final Color color;
  final double depth;
}

/// The painter projects textured Minecraft cuboids with a perspective camera.
/// Texture pixels are painted as quads to keep nearest-neighbour pixel art
/// and transparent outer layers independent of the underlying 3D backend.
class _SkinPainter extends CustomPainter {
  _SkinPainter({required this.textures, required this.slim, required this.animationTime, required this.yaw, required this.pitch, required this.zoom, required this.cape}) : super(repaint: animationTime);

  final _SkinTextures textures;
  final bool slim;
  final ValueListenable<double> animationTime;
  final double yaw;
  final double pitch;
  final double zoom;
  final img.Image? cape;

  @override
  void paint(Canvas canvas, Size size) {
    final faces = <_Face>[];
    final skin = textures.skin;
    final modern = skin.height == skin.width;
    final t = animationTime.value * 8;
    final swing = math.sin(t) * 0.5;
    final armWidth = slim ? 3 : 4;

    void part({
      required _Point3 center,
      required int width,
      required int height,
      required int depth,
      required int u,
      required int v,
      int? outerU,
      int? outerV,
      _Point3? pivot,
      double angle = 0,
      bool mirror = false,
    }) {
      _addBox(faces, size, skin, center, width, height, depth, u, v, pivot: pivot, angle: angle, mirror: mirror);
      if (outerU != null && outerV != null) {
        _addBox(faces, size, skin, center, width, height, depth, outerU, outerV, pivot: pivot, angle: angle, mirror: mirror, inflate: width == 8 && height == 8 ? 0.5 : 0.25);
      }
    }

    part(center: const _Point3(0, -12, 0), width: 8, height: 8, depth: 8, u: 0, v: 0, outerU: 32, outerV: 0, pivot: const _Point3(0, -8, 0), angle: math.sin(t / 5) * 0.1);
    part(center: const _Point3(0, -2, 0), width: 8, height: 12, depth: 4, u: 16, v: 16, outerU: modern ? 16 : null, outerV: modern ? 32 : null);
    part(
      center: _Point3(-4 - armWidth / 2, -2, 0),
      width: armWidth,
      height: 12,
      depth: 4,
      u: modern ? 32 : 40,
      v: modern ? 48 : 16,
      outerU: modern ? 48 : null,
      outerV: modern ? 48 : null,
      pivot: const _Point3(-5, -6, 0),
      angle: -swing,
      mirror: !modern,
    );
    part(center: _Point3(4 + armWidth / 2, -2, 0), width: armWidth, height: 12, depth: 4, u: 40, v: 16, outerU: modern ? 40 : null, outerV: modern ? 32 : null, pivot: const _Point3(5, -6, 0), angle: swing);
    part(center: const _Point3(-2, 10, 0), width: 4, height: 12, depth: 4, u: modern ? 16 : 0, v: modern ? 48 : 16, outerU: modern ? 0 : null, outerV: modern ? 48 : null, pivot: const _Point3(-2, 4, 0), angle: swing, mirror: !modern);
    part(center: const _Point3(2, 10, 0), width: 4, height: 12, depth: 4, u: 0, v: 16, outerU: modern ? 0 : null, outerV: modern ? 32 : null, pivot: const _Point3(2, 4, 0), angle: -swing);
    final capeTexture = cape;
    if (capeTexture != null) {
      _addBox(faces, size, capeTexture, const _Point3(0, 0, -3.25), 10, 16, 1, 0, 0, pivot: const _Point3(0, -8, -2.6), angle: -(0.19 + math.sin(t / 1.5) * 0.06), isCape: true);
    }

    faces.sort((a, b) => a.depth.compareTo(b.depth));
    final paint = Paint()..isAntiAlias = false;
    for (var start = 0; start < faces.length; start += 10000) {
      final points = <Offset>[];
      final colors = <Color>[];
      final indices = <int>[];
      for (final face in faces.skip(start).take(10000)) {
        final base = points.length;
        points.addAll(face.points);
        colors.addAll([face.color, face.color, face.color, face.color]);
        indices.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
      }
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        points,
        colors: colors,
        indices: indices,
      );
      canvas.drawVertices(vertices, BlendMode.src, paint);
      vertices.dispose();
    }
  }

  void _addBox(List<_Face> faces, Size size, img.Image image, _Point3 center, int w, int h, int d, int u, int v, {_Point3? pivot, double angle = 0, bool mirror = false, double inflate = 0, bool isCape = false}) {
    final x0 = center.x - w / 2 - inflate;
    final x1 = center.x + w / 2 + inflate;
    final y0 = center.y - h / 2 - inflate;
    final y1 = center.y + h / 2 + inflate;
    final z0 = center.z - d / 2 - inflate;
    final z1 = center.z + d / 2 + inflate;

    void face(List<_Point3> corners, int tx, int ty, int tw, int th, {bool flipX = false, bool flipY = false}) {
      final transformed = corners.map((p) => _camera(_rotatePart(p, pivot, angle))).toList();
      final a = transformed[0];
      final b = transformed[1];
      final c = transformed[2];
      final normalX = (b.y - a.y) * (c.z - a.z) - (b.z - a.z) * (c.y - a.y);
      final normalY = (b.z - a.z) * (c.x - a.x) - (b.x - a.x) * (c.z - a.z);
      final normalZ = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
      if (normalX * -a.x + normalY * -a.y + normalZ * (60 - a.z) <= 0) return;
      final length = math.sqrt(normalX * normalX + normalY * normalY + normalZ * normalZ);
      final light = (0.78 + 0.22 * (normalZ / length).abs()).clamp(0.0, 1.0);
      final scale = image.width / 64;
      final pixelWidth = (tw * scale).round();
      final pixelHeight = (th * scale).round();
      if (pixelWidth <= 0 || pixelHeight <= 0) return;
      for (var py = 0; py < pixelHeight; py++) {
        for (var px = 0; px < pixelWidth; px++) {
          final sx = (tx * scale).round() + (flipX != mirror ? pixelWidth - 1 - px : px);
          final sy = (ty * scale).round() + (flipY ? pixelHeight - 1 - py : py);
          if (sx < 0 || sy < 0 || sx >= image.width || sy >= image.height) continue;
          final pixel = image.getPixel(sx, sy);
          if (pixel.a == 0) continue;
          final color = Color.fromARGB(pixel.a.toInt(), (pixel.r * light).round(), (pixel.g * light).round(), (pixel.b * light).round());
          final left = px / pixelWidth;
          final right = (px + 1) / pixelWidth;
          final top = py / pixelHeight;
          final bottom = (py + 1) / pixelHeight;
          final p0 = _facePoint(transformed, left, top);
          final p1 = _facePoint(transformed, right, top);
          final p2 = _facePoint(transformed, right, bottom);
          final p3 = _facePoint(transformed, left, bottom);
          final projected = [_project(p0, size), _project(p1, size), _project(p2, size), _project(p3, size)];
          final midpoint = Offset(
            projected.fold<double>(0, (sum, point) => sum + point.dx) / 4,
            projected.fold<double>(0, (sum, point) => sum + point.dy) / 4,
          );
          faces.add(_Face(
            projected.map((point) {
              final offset = point - midpoint;

              return offset.distance == 0 ? point : point + offset / offset.distance * 0.08;
            }).toList(),
            color,
            (p0.z + p1.z + p2.z + p3.z) / 4,
          ));
        }
      }
    }

    face([_Point3(x0, y0, z1), _Point3(x1, y0, z1), _Point3(x1, y1, z1), _Point3(x0, y1, z1)], u + (isCape ? 2 * d + w : d), v + d, w, h);
    face([_Point3(x1, y0, z0), _Point3(x0, y0, z0), _Point3(x0, y1, z0), _Point3(x1, y1, z0)], u + (isCape ? d : 2 * d + w), v + d, w, h);
    face([_Point3(x1, y0, z1), _Point3(x1, y0, z0), _Point3(x1, y1, z0), _Point3(x1, y1, z1)], (mirror || isCape) ? u + d + w : u, v + d, d, h, flipX: isCape);
    face([_Point3(x0, y0, z0), _Point3(x0, y0, z1), _Point3(x0, y1, z1), _Point3(x0, y1, z0)], (mirror || isCape) ? u : u + d + w, v + d, d, h, flipX: isCape);
    face([_Point3(x0, y0, z0), _Point3(x1, y0, z0), _Point3(x1, y0, z1), _Point3(x0, y0, z1)], u + d, v, w, d, flipX: isCape, flipY: isCape);
    face([_Point3(x0, y1, z1), _Point3(x1, y1, z1), _Point3(x1, y1, z0), _Point3(x0, y1, z0)], u + d + w, v, w, d, flipX: isCape, flipY: !isCape);
  }

  static _Point3 _interpolate(_Point3 a, _Point3 b, double t) => _Point3(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t);

  static _Point3 _facePoint(List<_Point3> corners, double x, double y) => _interpolate(_interpolate(corners[0], corners[1], x), _interpolate(corners[3], corners[2], x), y);

  static _Point3 _rotatePart(_Point3 p, _Point3? pivot, double angle) {
    if (pivot == null) return p;
    final y = p.y - pivot.y;
    final z = p.z - pivot.z;

    return _Point3(p.x, pivot.y + y * math.cos(angle) - z * math.sin(angle), pivot.z + y * math.sin(angle) + z * math.cos(angle));
  }

  _Point3 _camera(_Point3 p) {
    final x = p.x * math.cos(yaw) + p.z * math.sin(yaw);
    final z = -p.x * math.sin(yaw) + p.z * math.cos(yaw);

    return _Point3(x, p.y * math.cos(pitch) + z * math.sin(pitch), -p.y * math.sin(pitch) + z * math.cos(pitch));
  }

  Offset _project(_Point3 p, Size size) {
    final scale = size.height * 1.65 * zoom / (60 - p.z);

    return Offset(size.width / 2 + p.x * scale, size.height / 2 + p.y * scale);
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) =>
      textures != oldDelegate.textures || cape != oldDelegate.cape || slim != oldDelegate.slim || animationTime != oldDelegate.animationTime || yaw != oldDelegate.yaw || pitch != oldDelegate.pitch || zoom != oldDelegate.zoom;
}

class ThreeDimensionalViewer {
  static Future<Uint8List> getImageBytes(ImageProvider imageProvider) async {
    final completer = Completer<Uint8List>();
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) async {
        try {
          final data = await info.image.toByteData(format: ui.ImageByteFormat.png);
          if (data == null) throw StateError('Unable to encode image');
          if (!completer.isCompleted) completer.complete(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        } catch (error, stack) {
          if (!completer.isCompleted) completer.completeError(error, stack);
        } finally {
          info.dispose();
        }
      },
      onError: (Object error, StackTrace? stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    try {
      return await completer.future.timeout(const Duration(seconds: 8));
    } finally {
      stream.removeListener(listener);
    }
  }
}
