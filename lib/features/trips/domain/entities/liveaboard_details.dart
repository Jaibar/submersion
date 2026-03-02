import 'package:equatable/equatable.dart';

/// Liveaboard vessel and logistics details, linked 1:1 to a Trip
class LiveaboardDetails extends Equatable {
  final String id;
  final String tripId;
  final String vesselName;
  final String? operatorName;
  final String? vesselType;
  final String? cabinType;
  final int? capacity;
  final String? embarkPort;
  final double? embarkLatitude;
  final double? embarkLongitude;
  final String? disembarkPort;
  final double? disembarkLatitude;
  final double? disembarkLongitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LiveaboardDetails({
    required this.id,
    required this.tripId,
    required this.vesselName,
    this.operatorName,
    this.vesselType,
    this.cabinType,
    this.capacity,
    this.embarkPort,
    this.embarkLatitude,
    this.embarkLongitude,
    this.disembarkPort,
    this.disembarkLatitude,
    this.disembarkLongitude,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasEmbarkCoordinates =>
      embarkLatitude != null && embarkLongitude != null;

  bool get hasDisembarkCoordinates =>
      disembarkLatitude != null && disembarkLongitude != null;

  LiveaboardDetails copyWith({
    String? id,
    String? tripId,
    String? vesselName,
    Object? operatorName = _undefined,
    Object? vesselType = _undefined,
    Object? cabinType = _undefined,
    Object? capacity = _undefined,
    Object? embarkPort = _undefined,
    Object? embarkLatitude = _undefined,
    Object? embarkLongitude = _undefined,
    Object? disembarkPort = _undefined,
    Object? disembarkLatitude = _undefined,
    Object? disembarkLongitude = _undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveaboardDetails(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      vesselName: vesselName ?? this.vesselName,
      operatorName: operatorName == _undefined
          ? this.operatorName
          : operatorName as String?,
      vesselType: vesselType == _undefined
          ? this.vesselType
          : vesselType as String?,
      cabinType: cabinType == _undefined
          ? this.cabinType
          : cabinType as String?,
      capacity: capacity == _undefined ? this.capacity : capacity as int?,
      embarkPort: embarkPort == _undefined
          ? this.embarkPort
          : embarkPort as String?,
      embarkLatitude: embarkLatitude == _undefined
          ? this.embarkLatitude
          : embarkLatitude as double?,
      embarkLongitude: embarkLongitude == _undefined
          ? this.embarkLongitude
          : embarkLongitude as double?,
      disembarkPort: disembarkPort == _undefined
          ? this.disembarkPort
          : disembarkPort as String?,
      disembarkLatitude: disembarkLatitude == _undefined
          ? this.disembarkLatitude
          : disembarkLatitude as double?,
      disembarkLongitude: disembarkLongitude == _undefined
          ? this.disembarkLongitude
          : disembarkLongitude as double?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tripId,
    vesselName,
    operatorName,
    vesselType,
    cabinType,
    capacity,
    embarkPort,
    embarkLatitude,
    embarkLongitude,
    disembarkPort,
    disembarkLatitude,
    disembarkLongitude,
    createdAt,
    updatedAt,
  ];
}

// Sentinel value for distinguishing null from undefined in copyWith
const _undefined = Object();
