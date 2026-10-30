import 'package:equatable/equatable.dart';
import 'room.dart';

/// A single floor's worth of generated rooms.
class FloorLayout extends Equatable {
  final int floorIndex;
  final List<Room> rooms;
  final double coveredAreaSqFt;

  const FloorLayout({
    required this.floorIndex,
    required this.rooms,
    required this.coveredAreaSqFt,
  });

  @override
  List<Object?> get props => [floorIndex, rooms, coveredAreaSqFt];
}

/// The complete output of the procedural floor plan engine: geometry only,
/// no images. This is what Material Estimation consumes directly, and what
/// the CustomPainter renders as a 2D plan.
class FloorPlanResult extends Equatable {
  final String id;
  final double plotWidthFeet;
  final double plotLengthFeet;
  final String plotFacing;
  final List<FloorLayout> floors;
  final double totalCoveredAreaSqFt;
  final double totalWallLengthFt;
  final double wallThicknessInches;
  final DateTime generatedAt;

  const FloorPlanResult({
    required this.id,
    required this.plotWidthFeet,
    required this.plotLengthFeet,
    required this.plotFacing,
    required this.floors,
    required this.totalCoveredAreaSqFt,
    required this.totalWallLengthFt,
    required this.wallThicknessInches,
    required this.generatedAt,
  });

  double get plotAreaSqFt => plotWidthFeet * plotLengthFeet;

  String get shortSummary =>
      '${plotWidthFeet.toStringAsFixed(0)}x${plotLengthFeet.toStringAsFixed(0)} ft plot, '
      '${floors.length} floor(s), '
      '${floors.fold<int>(0, (sum, f) => sum + f.rooms.length)} rooms, '
      'facing $plotFacing';

  @override
  List<Object?> get props => [
        id,
        plotWidthFeet,
        plotLengthFeet,
        plotFacing,
        floors,
        totalCoveredAreaSqFt,
        totalWallLengthFt,
        wallThicknessInches,
        generatedAt,
      ];
}
