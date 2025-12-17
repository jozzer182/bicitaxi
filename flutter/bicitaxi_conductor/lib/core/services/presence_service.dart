import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'geo_cell_service.dart';

/// User role for presence tracking.
enum PresenceRole { driver, client }

/// Presence data model.
class PresenceData {
  final String uid;
  final PresenceRole role;
  final DateTime lastSeen;
  final DateTime expiresAt;
  final double lat;
  final double lng;
  final String cellId;
  final String? activeRideId;
  final String platform;
  final String app;
  final DateTime updatedAt;

  PresenceData({
    required this.uid,
    required this.role,
    required this.lastSeen,
    required this.expiresAt,
    required this.lat,
    required this.lng,
    required this.cellId,
    this.activeRideId,
    required this.platform,
    required this.app,
    required this.updatedAt,
  });

  factory PresenceData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PresenceData(
      uid: data['uid'] ?? doc.id,
      role: data['role'] == 'driver'
          ? PresenceRole.driver
          : PresenceRole.client,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      cellId: data['cellId'] ?? '',
      activeRideId: data['activeRideId'],
      platform: data['platform'] ?? 'unknown',
      app: data['app'] ?? 'unknown',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role == PresenceRole.driver ? 'driver' : 'client',
      'lastSeen': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'lat': lat,
      'lng': lng,
      'cellId': cellId,
      'activeRideId': activeRideId,
      'platform': platform,
      'app': app,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool get isStale {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 4));
    return lastSeen.isBefore(cutoff);
  }
}

/// Service for managing user presence in geographic cells.
class PresenceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String appName;
  final PresenceRole role;

  Timer? _heartbeatTimer;
  String? _currentCellId;
  StreamSubscription<DocumentSnapshot>? _presenceSubscription;

  /// Heartbeat interval (3 minutes)
  static const Duration heartbeatInterval = Duration(minutes: 3);

  /// Presence TTL (24 hours)
  static const Duration presenceTtl = Duration(hours: 24);

  /// Stale threshold (4 minutes) - drivers not seen in this time are considered offline
  static const Duration staleThreshold = Duration(minutes: 4);

  PresenceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required this.appName,
    required this.role,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Gets the current user ID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Gets the Firestore reference for a presence document.
  DocumentReference _presenceRef(String cellId, String uid) {
    return _firestore
        .collection('cells')
        .doc(cellId)
        .collection('presence')
        .doc(uid);
  }

  /// Updates presence in the given cell.
  Future<void> updatePresence({
    required double lat,
    required double lng,
    String? activeRideId,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      print('⚠️ PresenceService: No authenticated user');
      return;
    }

    final cellId = GeoCellService.computeCellIdFromCoords(lat, lng);
    final canonical = GeoCellService.computeCanonical(lat, lng);

    print('📍 Updating presence: cellId=$cellId, canonical=$canonical');

    // If cell changed, delete old presence
    if (_currentCellId != null && _currentCellId != cellId) {
      await _deletePresence(_currentCellId!, uid);
    }

    final presence = PresenceData(
      uid: uid,
      role: role,
      lastSeen: DateTime.now(),
      expiresAt: DateTime.now().add(presenceTtl),
      lat: lat,
      lng: lng,
      cellId: cellId,
      activeRideId: activeRideId,
      platform: 'flutter_android',
      app: appName,
      updatedAt: DateTime.now(),
    );

    await _presenceRef(cellId, uid).set(presence.toFirestore());
    _currentCellId = cellId;

    print('✅ Presence updated in cell: $cellId');
  }

  /// Deletes presence from a cell.
  Future<void> _deletePresence(String cellId, String uid) async {
    try {
      await _presenceRef(cellId, uid).delete();
      print('🗑️ Deleted old presence from cell: $cellId');
    } catch (e) {
      print('⚠️ Failed to delete old presence: $e');
    }
  }

  /// Starts the heartbeat timer for presence updates.
  void startHeartbeat({
    required double Function() getLatitude,
    required double Function() getLongitude,
    String? Function()? getActiveRideId,
  }) {
    stopHeartbeat();

    // Immediate first update
    updatePresence(
      lat: getLatitude(),
      lng: getLongitude(),
      activeRideId: getActiveRideId?.call(),
    );

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      updatePresence(
        lat: getLatitude(),
        lng: getLongitude(),
        activeRideId: getActiveRideId?.call(),
      );
    });

    print('💓 Heartbeat started (interval: ${heartbeatInterval.inMinutes}m)');
  }

  /// Stops the heartbeat timer.
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    print('💔 Heartbeat stopped');
  }

  /// Removes presence when going offline.
  Future<void> goOffline() async {
    stopHeartbeat();

    final uid = currentUserId;
    if (uid != null && _currentCellId != null) {
      await _deletePresence(_currentCellId!, uid);
      _currentCellId = null;
    }

    print('📴 User went offline');
  }

  /// Counts active drivers in the given cells (current + 8 neighbors).
  /// Filters out drivers whose lastSeen is older than staleThreshold.
  Stream<int> watchDriverCount(double lat, double lng) {
    final cellIds = GeoCellService.computeAllCellIds(lat, lng);

    print('👀 Watching driver count in ${cellIds.length} cells');

    // Create streams for each cell - get ALL drivers then filter client-side
    // This ensures the stale check is always fresh, not a static timestamp
    final streams = cellIds.map((cellId) {
      return _firestore
          .collection('cells')
          .doc(cellId)
          .collection('presence')
          .where('role', isEqualTo: 'driver')
          .snapshots()
          .map((snapshot) {
            // Filter client-side with FRESH cutoff on each update
            final now = DateTime.now();
            final cutoff = now.subtract(staleThreshold);

            final freshDrivers = snapshot.docs.where((doc) {
              final data = doc.data();
              final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
              if (lastSeen == null) return false;
              return lastSeen.isAfter(cutoff);
            }).toList();

            if (freshDrivers.isNotEmpty) {
              print(
                '✅ Found ${freshDrivers.length} fresh driver(s) in cell: $cellId',
              );
            }

            return freshDrivers.length;
          });
    }).toList();

    // Combine all streams and sum the counts
    return _combineStreams(streams);
  }

  /// Combines multiple integer streams into a sum.
  Stream<int> _combineStreams(List<Stream<int>> streams) {
    if (streams.isEmpty) return Stream.value(0);
    if (streams.length == 1) return streams.first;

    final controller = StreamController<int>.broadcast();
    final counts = List<int>.filled(streams.length, 0);
    final subscriptions = <StreamSubscription<int>>[];

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      subscriptions.add(
        streams[i].listen((count) {
          counts[index] = count;
          final total = counts.fold<int>(0, (sum, c) => sum + c);
          controller.add(total);
        }),
      );
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Gets a real-time stream of active drivers in nearby cells.
  /// Filters out drivers whose lastSeen is older than staleThreshold.
  Stream<List<PresenceData>> watchNearbyDrivers(double lat, double lng) {
    final cellIds = GeoCellService.computeAllCellIds(lat, lng);

    // Query ALL drivers, then filter client-side with fresh cutoff
    final streams = cellIds.map((cellId) {
      return _firestore
          .collection('cells')
          .doc(cellId)
          .collection('presence')
          .where('role', isEqualTo: 'driver')
          .snapshots()
          .map((snapshot) {
            // Filter with FRESH cutoff on each snapshot update
            final now = DateTime.now();
            final cutoff = now.subtract(staleThreshold);

            return snapshot.docs
                .where((doc) {
                  final data = doc.data();
                  final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
                  if (lastSeen == null) return false;
                  return lastSeen.isAfter(cutoff);
                })
                .map((doc) => PresenceData.fromFirestore(doc))
                .toList();
          });
    }).toList();

    return _combineListStreams(streams);
  }

  /// Combines multiple list streams into a single flattened list.
  Stream<List<PresenceData>> _combineListStreams(
    List<Stream<List<PresenceData>>> streams,
  ) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    final controller = StreamController<List<PresenceData>>.broadcast();
    final lists = List<List<PresenceData>>.filled(streams.length, []);
    final subscriptions = <StreamSubscription<List<PresenceData>>>[];

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      subscriptions.add(
        streams[i].listen((list) {
          lists[index] = list;
          final combined = lists.expand((l) => l).toList();
          controller.add(combined);
        }),
      );
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Cleans up resources.
  void dispose() {
    stopHeartbeat();
    _presenceSubscription?.cancel();
  }
}
