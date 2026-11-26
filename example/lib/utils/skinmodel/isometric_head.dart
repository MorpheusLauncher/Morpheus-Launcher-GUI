import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_utils.dart';

/// Small, locally rendered preview using the same cached skin as the 3D model.
class IsometricHead extends StatefulWidget {
  const IsometricHead({super.key, required this.account});

  final Account account;

  @override
  State<IsometricHead> createState() => _IsometricHeadState();
}

class _IsometricHeadState extends State<IsometricHead> {
  static final _images = <String, Future<ui.Image>>{};
  late Future<ui.Image> _image;

  String get _key {
    final a = widget.account;

    return 'head-v1:${a.uuid}:${a.username}:${a.isPremium}:${a.isElyBy}:${a.isSlimSkin}:${SkinUtils.cacheRevision.value}';
  }

  void _load() {
    final key = _key;
    if (_images.length >= 100 && !_images.containsKey(key)) _images.remove(_images.keys.first);
    _image = _images.putIfAbsent(key, () async {
      ui.Image skin;
      try {
        skin = await _decode(await SkinUtils.loadSkinBytes(widget.account));
      } catch (_) {
        final data = await rootBundle.load(widget.account.isSlimSkin ? 'assets/alex-raw.png' : 'assets/steve-raw.png');
        skin = await _decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
      try {
        const resolution = 160;
        final recorder = ui.PictureRecorder();
        _HeadPainter(skin).paint(Canvas(recorder), const Size(160, 160));
        final picture = recorder.endRecording();
        try {
          return await picture.toImage(resolution, resolution);
        } finally {
          picture.dispose();
        }
      } finally {
        skin.dispose();
      }
    });
  }

  static Future<ui.Image> _decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final image = (await codec.getNextFrame()).image;
      if (image.width < 64 || image.width % 64 != 0 || (image.height != image.width && image.height * 2 != image.width)) {
        image.dispose();
        throw const FormatException('Invalid Minecraft skin');
      }

      return image;
    } finally {
      codec.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant IsometricHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _image,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) return const SizedBox.expand();

        return RawImage(image: image, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
      },
    );
  }
}

class _HeadPainter extends CustomPainter {
  _HeadPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = image.width / 64;
    final paint = Paint()..filterQuality = FilterQuality.none;

    void face(int x, int y, Offset origin, Offset horizontal, Offset vertical) {
      canvas.save();
      canvas.transform(Float64List.fromList([horizontal.dx, horizontal.dy, 0, 0, vertical.dx, vertical.dy, 0, 0, 0, 0, 1, 0, origin.dx, origin.dy, 0, 1]));
      const destination = Rect.fromLTWH(0, 0, 1, 1);
      for (final layer in [0, 32]) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH((x + layer) * scale, y * scale, 8 * scale, 8 * scale),
          destination,
          paint,
        );
      }
      canvas.restore();
    }

    final edge = math.min(size.width / math.sqrt(3), size.height / 2) * .92;
    final dx = edge * math.sqrt(3) / 2;
    final dy = edge / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final left = Offset(center.dx - dx, center.dy - dy);
    face(8, 0, left, Offset(dx, -dy), Offset(dx, dy));
    face(0, 8, left, Offset(dx, dy), Offset(0, edge));
    face(8, 8, center, Offset(dx, -dy), Offset(0, edge));
  }

  @override
  bool shouldRepaint(covariant _HeadPainter oldDelegate) => oldDelegate.image != image;
}
