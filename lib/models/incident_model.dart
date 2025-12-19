import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String reporterId;
  final String type; // Fire, Medical, Police, Crash, Other
  final String description;
  final String photoUrl;
  final String? folder; // Cloudinary folder
  final double latitude;
  final double longitude;
  final String address;
  final String status; // Pending, Responding, Resolved
  final DateTime timestamp;

  IncidentModel({
    required this.id,
    required this.reporterId,
    required this.type,
    required this.description,
    required this.photoUrl,
    this.folder,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterId': reporterId,
      'type': type,
      'description': description,
      'photoUrl': photoUrl,
      'folder': folder,
      'location': GeoPoint(latitude, longitude),
      'address': address,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map, String id) {
    return IncidentModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      type: map['type'] ?? 'Other',
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      folder: map['folder'],
      latitude: (map['location'] as GeoPoint).latitude,
      longitude: (map['location'] as GeoPoint).longitude,
      address: map['address'] ?? '',
      status: map['status'] ?? 'Pending',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
