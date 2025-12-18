import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for a ride history entry
class RideHistoryEntry {
  final String rideId;
  final String role; // 'client' or 'driver'

  // Locations
  final double pickupLat;
  final double pickupLng;
  final String? pickupAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffAddress;

  // Parties
  final String clientUid;
  final String clientName;
  final String? driverUid;
  final String? driverName;

  // Timeline
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  // Status
  final String status; // 'pending', 'assigned', 'completed', 'cancelled'

  RideHistoryEntry({
    required this.rideId,
    required this.role,
    required this.pickupLat,
    required this.pickupLng,
    this.pickupAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffAddress,
    required this.clientUid,
    required this.clientName,
    this.driverUid,
    this.driverName,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.cancelledAt,
    required this.status,
  });

  factory RideHistoryEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return RideHistoryEntry(
      rideId: id,
      role: data['role'] ?? 'client',
      pickupLat: (data['pickupLat'] ?? 0).toDouble(),
      pickupLng: (data['pickupLng'] ?? 0).toDouble(),
      pickupAddress: data['pickupAddress'],
      dropoffLat: data['dropoffLat']?.toDouble(),
      dropoffLng: data['dropoffLng']?.toDouble(),
      dropoffAddress: data['dropoffAddress'],
      clientUid: data['clientUid'] ?? '',
      clientName: data['clientName'] ?? 'Cliente',
      driverUid: data['driverUid'],
      driverName: data['driverName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupAddress': pickupAddress,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'dropoffAddress': dropoffAddress,
      'clientUid': clientUid,
      'clientName': clientName,
      'driverUid': driverUid,
      'driverName': driverName,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'cancelledAt': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
      'status': status,
    };
  }

  /// Display string for the ride date
  String get dateString {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      return 'Hoy ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Status display text
  String get statusText {
    switch (status) {
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      case 'assigned':
        return 'En curso';
      default:
        return 'Pendiente';
    }
  }
}

/// Service to manage ride history in Firestore
/// Each user has their own history collection at /users/{uid}/history/
class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get reference to user's history collection
  CollectionReference<Map<String, dynamic>> _historyRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('history');
  }

  /// Save or update history entry for a user
  Future<void> saveHistoryEntry(
    String uid,
    String rideId,
    RideHistoryEntry entry,
  ) async {
    await _historyRef(
      uid,
    ).doc(rideId).set(entry.toFirestore(), SetOptions(merge: true));
    print('📜 Saved history entry for user $uid, ride $rideId');
  }

  /// Update history entry status
  Future<void> updateHistoryStatus(
    String uid,
    String rideId,
    String status, {
    DateTime? assignedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? driverUid,
    String? driverName,
  }) async {
    final updates = <String, dynamic>{'status': status};

    if (assignedAt != null)
      updates['assignedAt'] = Timestamp.fromDate(assignedAt);
    if (completedAt != null)
      updates['completedAt'] = Timestamp.fromDate(completedAt);
    if (cancelledAt != null)
      updates['cancelledAt'] = Timestamp.fromDate(cancelledAt);
    if (driverUid != null) updates['driverUid'] = driverUid;
    if (driverName != null) updates['driverName'] = driverName;

    await _historyRef(uid).doc(rideId).update(updates);
    print('📜 Updated history status for user $uid, ride $rideId: $status');
  }

  /// Watch user's ride history (stream)
  Stream<List<RideHistoryEntry>> watchHistory(String uid) {
    return _historyRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RideHistoryEntry.fromFirestore(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Get user's ride history (one-time fetch)
  Future<List<RideHistoryEntry>> getHistory(String uid) async {
    final snapshot = await _historyRef(
      uid,
    ).orderBy('createdAt', descending: true).limit(50).get();

    return snapshot.docs.map((doc) {
      return RideHistoryEntry.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  /// Create client history entry when request is created
  Future<void> createClientHistoryEntry({
    required String rideId,
    required String clientUid,
    required String clientName,
    required double pickupLat,
    required double pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
  }) async {
    final entry = RideHistoryEntry(
      rideId: rideId,
      role: 'client',
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      dropoffAddress: dropoffAddress,
      clientUid: clientUid,
      clientName: clientName,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await saveHistoryEntry(clientUid, rideId, entry);
  }

  /// Create driver history entry when ride is accepted
  Future<void> createDriverHistoryEntry({
    required String rideId,
    required String clientUid,
    required String clientName,
    required String driverUid,
    required String driverName,
    required double pickupLat,
    required double pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
  }) async {
    final entry = RideHistoryEntry(
      rideId: rideId,
      role: 'driver',
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      pickupAddress: pickupAddress,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      dropoffAddress: dropoffAddress,
      clientUid: clientUid,
      clientName: clientName,
      driverUid: driverUid,
      driverName: driverName,
      createdAt: DateTime.now(),
      assignedAt: DateTime.now(),
      status: 'assigned',
    );

    await saveHistoryEntry(driverUid, rideId, entry);
  }

  /// Mark ride as completed for both parties
  Future<void> markRideCompleted(
    String rideId,
    String clientUid,
    String? driverUid,
  ) async {
    final now = DateTime.now();

    // Update client's history
    await updateHistoryStatus(clientUid, rideId, 'completed', completedAt: now);

    // Update driver's history if driver exists
    if (driverUid != null) {
      await updateHistoryStatus(
        driverUid,
        rideId,
        'completed',
        completedAt: now,
      );
    }
  }

  /// Mark ride as cancelled
  Future<void> markRideCancelled(
    String rideId,
    String clientUid,
    String? driverUid,
  ) async {
    final now = DateTime.now();

    // Update client's history
    await updateHistoryStatus(clientUid, rideId, 'cancelled', cancelledAt: now);

    // Update driver's history if driver was assigned
    if (driverUid != null) {
      await updateHistoryStatus(
        driverUid,
        rideId,
        'cancelled',
        cancelledAt: now,
      );
    }
  }
}
