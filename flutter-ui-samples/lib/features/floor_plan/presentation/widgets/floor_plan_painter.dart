import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/floor_plan_result.dart';
import '../../domain/entities/room.dart';

/// Renders one [FloorLayout] as an architectural-blueprint-style 2D plan:
/// thickness-aware walls, door swing symbols on internal walls, window
/// tick-marks on exterior (plot-boundary-facing) walls, plus room labels
/// and dimensions. Pure Flutter CustomPainter - no AI, no external
/// rendering service - so this is instant and works fully offline.
class FloorPlanPainter extends CustomPainter {
  final FloorLayout floor;
  final double plotWidthFeet;
  final double plotLengthFeet;
  final double wallThicknessInches;

  FloorPlanPainter({
    required this.floor,
    required this.plotWidthFeet,
    required this.plotLengthFeet,
    this.wallThicknessInches = 9.0,
  });

  /// Room types that don't get door/window symbols - open-air or
  /// circulation spaces where a door/window symbol wouldn't read as
  /// architecturally meaningful.
  static const _openAirTypes = {
    RoomType.carPorch,
    RoomType.porch,
    RoomType.terrace,
    RoomType.balcony,
    RoomType.garden,
    RoomType.stairs,
    RoomType.corridor,
    RoomType.entrance,
  };

  static const Map<RoomType, Color> _roomColors = {
    RoomType.entrance: Color(0xFFFFECB3),
    RoomType.bedroom: Color(0xFFBBDEFB),
    RoomType.masterBedroom: Color(0xFF90CAF9),
    RoomType.bathroom: Color(0xFFB2DFDB),
    RoomType.attachedBathroom: Color(0xFF80CBC4),
    RoomType.kitchen: Color(0xFFFFE0B2),
    RoomType.drawingRoom: Color(0xFFD1C4E9),
    RoomType.tvLounge: Color(0xFFC5CAE9),
    RoomType.dining: Color(0xFFFFF9C4),
    RoomType.store: Color(0xFFD7CCC8),
    RoomType.laundry: Color(0xFFB3E5FC),
    RoomType.carPorch: Color(0xFFE0E0E0),
    RoomType.garage: Color(0xFFCFD8DC),
    RoomType.porch: Color(0xFFECEFF1),
    RoomType.terrace: Color(0xFFDCEDC8),
    RoomType.balcony: Color(0xFFE1F5FE),
    RoomType.stairs: Color(0xFFFFCCBC),
    RoomType.garden: Color(0xFFC8E6C9),
    RoomType.corridor: Color(0xFFF5F5F5),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 24.0;
    final availableW = size.width - padding * 2;
    final availableH = size.height - padding * 2;
    final scale = (availableW / plotWidthFeet)
        .clamp(0, availableH / plotLengthFeet)
        .toDouble();

    final offset = Offset(padding, padding);
    final wallThicknessPx = math.max(2.0, (wallThicknessInches / 12.0) * scale);
    const eps = 0.05; // feet tolerance for "touches plot boundary"

    // Plot boundary (heavy outer line, like a site boundary on a real plan).
    final plotRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      plotWidthFeet * scale,
      plotLengthFeet * scale,
    );
    canvas.drawRect(
      plotRect,
      Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = wallThicknessPx * 1.4,
    );

    for (final room in floor.rooms) {
      final rect = Rect.fromLTWH(
        offset.dx + room.x * scale,
        offset.dy + room.y * scale,
        room.width * scale,
        room.height * scale,
      );

      // Fill
      canvas.drawRect(rect, Paint()..color = _roomColors[room.type] ?? const Color(0xFFEEEEEE));

      // Thickness-aware wall outline.
      canvas.drawRect(
        rect,
        Paint()
          ..color = Colors.black87
          ..style = PaintingStyle.stroke
          ..strokeWidth = wallThicknessPx,
      );

      if (!_openAirTypes.contains(room.type)) {
        _drawWindows(canvas, room, rect, wallThicknessPx, eps);
        _drawDoor(canvas, room, rect, scale, wallThicknessPx, eps);
      }

      _drawLabel(canvas, rect, room);
    }
  }

  /// Draws small perpendicular tick marks (the standard architectural
  /// window symbol) along whichever wall segments of this room sit on the
  /// outer plot boundary.
  void _drawWindows(Canvas canvas, Room room, Rect rect, double wallPx, double eps) {
    final paint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = math.max(1.5, wallPx * 0.5);

    final touchesLeft = room.x <= eps;
    final touchesTop = room.y <= eps;
    final touchesRight = (room.x + room.width) >= plotWidthFeet - eps;
    final touchesBottom = (room.y + room.height) >= plotLengthFeet - eps;

    void tickHorizontal(double y) {
      // A window symbol on a horizontal wall: two short parallel ticks.
      final cx = rect.center.dx;
      final span = math.min(rect.width * 0.4, 30.0);
      canvas.drawLine(Offset(cx - span / 2, y - wallPx / 2), Offset(cx - span / 2, y + wallPx / 2), paint);
      canvas.drawLine(Offset(cx + span / 2, y - wallPx / 2), Offset(cx + span / 2, y + wallPx / 2), paint);
      canvas.drawLine(Offset(cx - span / 2, y), Offset(cx + span / 2, y), paint);
    }

    void tickVertical(double x) {
      final cy = rect.center.dy;
      final span = math.min(rect.height * 0.4, 30.0);
      canvas.drawLine(Offset(x - wallPx / 2, cy - span / 2), Offset(x + wallPx / 2, cy - span / 2), paint);
      canvas.drawLine(Offset(x - wallPx / 2, cy + span / 2), Offset(x + wallPx / 2, cy + span / 2), paint);
      canvas.drawLine(Offset(x, cy - span / 2), Offset(x, cy + span / 2), paint);
    }

    if (touchesTop && rect.width > 40) tickHorizontal(rect.top);
    if (touchesBottom && rect.width > 40) tickHorizontal(rect.bottom);
    if (touchesLeft && rect.height > 40) tickVertical(rect.left);
    if (touchesRight && rect.height > 40) tickVertical(rect.right);
  }

  /// Draws a door opening (gap in the wall) plus a quarter-circle swing
  /// arc, on whichever edge is most likely to be an internal circulation
  /// wall (preferring an edge that does NOT sit on the plot boundary).
  void _drawDoor(Canvas canvas, Room room, Rect rect, double scale, double wallPx, double eps) {
    if (rect.width < 30 || rect.height < 30) return;

    final touchesLeft = room.x <= eps;
    final touchesTop = room.y <= eps;
    final touchesRight = (room.x + room.width) >= plotWidthFeet - eps;
    final touchesBottom = (room.y + room.height) >= plotLengthFeet - eps;

    // Preference order: an edge NOT on the plot boundary first (internal
    // door), falling back to any edge so every room still gets a door.
    final candidates = <String>[
      if (!touchesBottom) 'bottom',
      if (!touchesTop) 'top',
      if (!touchesLeft) 'left',
      if (!touchesRight) 'right',
      'bottom',
    ];
    final edge = candidates.first;

    final doorWidthPx = math.min(3.0 * scale, edge == 'top' || edge == 'bottom' ? rect.width * 0.4 : rect.height * 0.4);
    if (doorWidthPx < 10) return;

    final doorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final swingPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    switch (edge) {
      case 'bottom':
        final startX = rect.left + rect.width * 0.15;
        final gapRect = Rect.fromLTWH(startX, rect.bottom - wallPx / 2, doorWidthPx, wallPx);
        canvas.drawRect(gapRect, doorPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(startX, rect.bottom), radius: doorWidthPx),
          -math.pi / 2,
          math.pi / 2,
          false,
          swingPaint,
        );
        canvas.drawLine(Offset(startX, rect.bottom), Offset(startX, rect.bottom - doorWidthPx), swingPaint);
        break;
      case 'top':
        final startX = rect.left + rect.width * 0.15;
        final gapRect = Rect.fromLTWH(startX, rect.top - wallPx / 2, doorWidthPx, wallPx);
        canvas.drawRect(gapRect, doorPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(startX, rect.top), radius: doorWidthPx),
          0,
          math.pi / 2,
          false,
          swingPaint,
        );
        canvas.drawLine(Offset(startX, rect.top), Offset(startX, rect.top + doorWidthPx), swingPaint);
        break;
      case 'left':
        final startY = rect.top + rect.height * 0.15;
        final gapRect = Rect.fromLTWH(rect.left - wallPx / 2, startY, wallPx, doorWidthPx);
        canvas.drawRect(gapRect, doorPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(rect.left, startY), radius: doorWidthPx),
          0,
          math.pi / 2,
          false,
          swingPaint,
        );
        canvas.drawLine(Offset(rect.left, startY), Offset(rect.left + doorWidthPx, startY), swingPaint);
        break;
      case 'right':
        final startY = rect.top + rect.height * 0.15;
        final gapRect = Rect.fromLTWH(rect.right - wallPx / 2, startY, wallPx, doorWidthPx);
        canvas.drawRect(gapRect, doorPaint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(rect.right, startY), radius: doorWidthPx),
          math.pi / 2,
          math.pi / 2,
          false,
          swingPaint,
        );
        canvas.drawLine(Offset(rect.right, startY), Offset(rect.right - doorWidthPx, startY), swingPaint);
        break;
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, Room room) {
    if (rect.width < 30 || rect.height < 20) return;
    final labelText =
        '${room.label}\n${room.width.toStringAsFixed(0)}x${room.height.toStringAsFixed(0)} ft';
    final tp = TextPainter(
      text: TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: rect.width - 4);

    final textOffset = Offset(
      rect.center.dx - tp.width / 2,
      rect.center.dy - tp.height / 2,
    );
    tp.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.floor != floor || oldDelegate.wallThicknessInches != wallThicknessInches;
  }
}
