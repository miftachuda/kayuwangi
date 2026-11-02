import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:kayuwangi/services/location_service.dart';

class WatermarkingService {
  static final WatermarkingService _instance = WatermarkingService._internal();
  factory WatermarkingService() => _instance;
  WatermarkingService._internal();

  /// Creates a stamped image with location info and a mini-map with a pin
  Future<File> stampImage({
    required File originalImageFile,
    required LocationResult location,
    required String plantNomor,
    required String plantSpecies,
    String? customNote,
  }) async {
    // 1. Read bytes from original file and decode to ui.Image
    final bytes = await originalImageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    final originalImage = frameInfo.image;

    final imgWidth = originalImage.width.toDouble();
    final imgHeight = originalImage.height.toDouble();

    // 2. Fetch mini map tile (or fallback to generated vector map)
    ui.Image? mapTileImage = await _tryFetchOsmTile(location.latitude, location.longitude);

    // 3. Setup canvas & picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgWidth, imgHeight));

    // Draw the original photo
    final paint = Paint();
    canvas.drawImage(originalImage, Offset.zero, paint);

    // 4. Calculate watermark banner dimensions based on image scale
    final bannerHeight = math.max(160.0, imgHeight * 0.22);
    final bannerRect = Rect.fromLTWH(0, imgHeight - bannerHeight, imgWidth, bannerHeight);

    // Draw dark semi-transparent HUD background
    final bannerPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, imgHeight - bannerHeight),
        Offset(0, imgHeight),
        [
          const Color(0xCC0A1A0F), // Dark deep green/black
          const Color(0xF5050C07),
        ],
      );
    canvas.drawRect(bannerRect, bannerPaint);

    // Top border highlight on banner
    final borderPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = math.max(2.0, imgWidth * 0.004)
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, imgHeight - bannerHeight),
      Offset(imgWidth, imgHeight - bannerHeight),
      borderPaint,
    );

    // 5. Draw Mini-Map Box with Pin
    final mapPadding = bannerHeight * 0.08;
    final mapBoxSize = bannerHeight - (mapPadding * 2);
    final mapBoxRect = Rect.fromLTWH(
      mapPadding * 1.5,
      (imgHeight - bannerHeight) + mapPadding,
      mapBoxSize,
      mapBoxSize,
    );

    _drawMiniMapBox(
      canvas: canvas,
      rect: mapBoxRect,
      mapTile: mapTileImage,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    // 6. Draw Text Details beside the Mini-Map
    final textLeft = mapBoxRect.right + (mapPadding * 1.5);
    final textWidth = imgWidth - textLeft - (mapPadding * 1.5);
    final textTop = (imgHeight - bannerHeight) + mapPadding;

    _drawInformationText(
      canvas: canvas,
      rect: Rect.fromLTWH(textLeft, textTop, textWidth, mapBoxSize),
      location: location,
      plantNomor: plantNomor,
      plantSpecies: plantSpecies,
      customNote: customNote,
      scaleFactor: bannerHeight / 200.0,
    );

    // 7. Finish painting and rasterize to file
    final picture = recorder.endRecording();
    final compositedImage = await picture.toImage(originalImage.width, originalImage.height);
    final byteData = await compositedImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Gagal memproses gambar watermarking.');
    }

    final tempDir = await getTemporaryDirectory();
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/kw_geotag_${timeStamp}.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(byteData.buffer.asUint8List());

    return outputFile;
  }

  /// Draw the mini map box with border, map background or tile, compass, and red pin marker
  void _drawMiniMapBox({
    required Canvas canvas,
    required Rect rect,
    required ui.Image? mapTile,
    required double latitude,
    required double longitude,
  }) {
    canvas.save();
    // Clip round rectangle for modern look
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    canvas.clipRRect(rrect);

    if (mapTile != null) {
      // Draw actual fetched map tile
      final srcRect = Rect.fromLTWH(0, 0, mapTile.width.toDouble(), mapTile.height.toDouble());
      canvas.drawImageRect(mapTile, srcRect, rect, Paint());
    } else {
      // Draw simulated high-tech topo map grid (offline fallback)
      final bgPaint = Paint()..color = const Color(0xFF263238);
      canvas.drawRect(rect, bgPaint);

      final gridPaint = Paint()
        ..color = const Color(0x3381C784)
        ..strokeWidth = 1.0;

      final step = rect.width / 6;
      for (double x = rect.left; x <= rect.right; x += step) {
        canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
      }
      for (double y = rect.top; y <= rect.bottom; y += step) {
        canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
      }

      // Draw simulated contours
      final contourPaint = Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(rect.center, rect.width * 0.35, contourPaint);
      canvas.drawCircle(rect.center, rect.width * 0.2, contourPaint);
    }

    // Mini Map dark vignette overlay around edges
    final vignettePaint = Paint()
      ..shader = ui.Gradient.radial(
        rect.center,
        rect.width * 0.65,
        [Colors.transparent, const Color(0x66000000)],
      );
    canvas.drawRect(rect, vignettePaint);

    // North Compass Badge (top-right of mini map)
    final compassCenter = Offset(rect.right - 14, rect.top + 14);
    final compassPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawCircle(compassCenter, 10, compassPaint);

    final compassText = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    compassText.paint(canvas, Offset(compassCenter.dx - (compassText.width / 2), compassCenter.dy - (compassText.height / 2)));

    // DRAW RED MAP PIN AT CENTER
    _drawPinMarker(canvas, rect.center, size: math.max(18.0, rect.width * 0.18));

    canvas.restore();

    // Outer white/green border around map
    final borderPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // "GPS MAP" tiny tag at bottom of map
    final tagRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + 4, rect.bottom - 16, 52, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(tagRRect, Paint()..color = const Color(0xCC1B5E20));

    final tagText = TextPainter(
      text: const TextSpan(
        text: 'LIVE MAP',
        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tagText.paint(canvas, Offset(rect.left + 6, rect.bottom - 15));
  }

  /// Draws a classic drop-pin marker with shadow and target ring
  void _drawPinMarker(Canvas canvas, Offset center, {double size = 26.0}) {
    final pinHeadRadius = size * 0.42;
    final pinTip = center;
    final pinCenter = Offset(center.dx, center.dy - (size * 0.65));

    // Pulsing target circle under pin
    final pulsePaint = Paint()
      ..color = const Color(0x88FF1744)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(pinTip, size * 0.35, pulsePaint);

    final dotPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(pinTip, 3.0, dotPaint);

    // Shadow under pin
    final shadowPaint = Paint()..color = const Color(0x66000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pinTip.dx + 2, pinTip.dy + 1), width: size * 0.5, height: size * 0.25),
      shadowPaint,
    );

    // Pin body (teardrop path)
    final pinPath = Path();
    pinPath.moveTo(pinTip.dx, pinTip.dy);
    // Left curve up to head
    pinPath.quadraticBezierTo(
      pinCenter.dx - pinHeadRadius * 1.1,
      pinCenter.dy + pinHeadRadius * 0.5,
      pinCenter.dx - pinHeadRadius,
      pinCenter.dy,
    );
    // Arc across the head
    pinPath.arcToPoint(
      Offset(pinCenter.dx + pinHeadRadius, pinCenter.dy),
      radius: Radius.circular(pinHeadRadius),
      clockwise: true,
    );
    // Right curve back to tip
    pinPath.quadraticBezierTo(
      pinCenter.dx + pinHeadRadius * 1.1,
      pinCenter.dy + pinHeadRadius * 0.5,
      pinTip.dx,
      pinTip.dy,
    );
    pinPath.close();

    // Fill Pin with bright Red
    final pinPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(pinCenter.dx, pinCenter.dy - pinHeadRadius),
        pinTip,
        [const Color(0xFFFF5252), const Color(0xFFD50000)],
      );
    canvas.drawPath(pinPath, pinPaint);

    // Pin outline
    final pinOutline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(pinPath, pinOutline);

    // Inner White Dot
    final innerDot = Paint()..color = Colors.white;
    canvas.drawCircle(pinCenter, pinHeadRadius * 0.45, innerDot);
  }

  /// Draws the informational text panel beside the mini map
  void _drawInformationText({
    required Canvas canvas,
    required Rect rect,
    required LocationResult location,
    required String plantNomor,
    required String plantSpecies,
    String? customNote,
    required double scaleFactor,
  }) {
    final titleSize = (13.0 * scaleFactor).clamp(11.0, 24.0);
    final headerSize = (15.0 * scaleFactor).clamp(13.0, 28.0);
    final normalSize = (11.0 * scaleFactor).clamp(9.0, 20.0);
    final smallSize = (10.0 * scaleFactor).clamp(8.0, 16.0);

    double currentY = rect.top;

    // 1. Tagline / App Name
    final systemText = TextPainter(
      text: TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.eco, color: Color(0xFF81C784), size: 14),
          ),
          TextSpan(
            text: ' KAYUWANGI PLANT MONITORING SYSTEM',
            style: TextStyle(
              color: const Color(0xFF81C784),
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    systemText.paint(canvas, Offset(rect.left, currentY));
    currentY += systemText.height + (3 * scaleFactor);

    // 2. Plant Number & Species
    final plantText = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '[$plantNomor] ',
            style: TextStyle(
              color: const Color(0xFFFFD54F), // Amber
              fontSize: headerSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: plantSpecies,
            style: TextStyle(
              color: Colors.white,
              fontSize: headerSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    plantText.paint(canvas, Offset(rect.left, currentY));
    currentY += plantText.height + (3 * scaleFactor);

    // 3. GPS Coordinates & Altitude
    final latDir = location.latitude >= 0 ? 'N' : 'S';
    final lngDir = location.longitude >= 0 ? 'E' : 'W';
    final coordStr = '📍 ${location.latitude.abs().toStringAsFixed(6)}° $latDir, ${location.longitude.abs().toStringAsFixed(6)}° $lngDir';
    final altStr = ' • Alt: ${location.altitude.toStringAsFixed(1)} m • Acc: ±${location.accuracy.toStringAsFixed(1)}m';

    final coordText = TextPainter(
      text: TextSpan(
        text: coordStr + altStr,
        style: TextStyle(
          color: const Color(0xFFE0E0E0),
          fontSize: normalSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    coordText.paint(canvas, Offset(rect.left, currentY));
    currentY += coordText.height + (2 * scaleFactor);

    // 4. Address / Area
    final addressText = TextPainter(
      text: TextSpan(
        text: '🏢 ${location.address}',
        style: TextStyle(
          color: const Color(0xFFB0BEC5),
          fontSize: smallSize,
        ),
      ),
      maxLines: 2,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    addressText.paint(canvas, Offset(rect.left, currentY));
    currentY += addressText.height + (2 * scaleFactor);

    // 5. Timestamp
    final now = DateTime.now();
    final timeStr = '⏱️ ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB';
    final timeText = TextPainter(
      text: TextSpan(
        text: timeStr,
        style: TextStyle(
          color: const Color(0xFF80CBC4),
          fontSize: smallSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    timeText.paint(canvas, Offset(rect.left, currentY));
  }

  /// Try to fetch OpenStreetMap tile image for the coordinate
  Future<ui.Image?> _tryFetchOsmTile(double lat, double lon) async {
    try {
      const zoom = 15;
      final n = math.pow(2.0, zoom);
      final x = ((lon + 180.0) / 360.0 * n).floor();
      final latRad = lat * math.pi / 180.0;
      final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();

      final url = 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'KayuwangiPlantMonitorApp/1.0 (contact@kayuwangi.app)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(response.bodyBytes);
        final frame = await codec.getNextFrame();
        return frame.image;
      }
    } catch (_) {
      // Offline fallback
    }
    return null;
  }
}
