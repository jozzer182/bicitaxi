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

  /// Creates a driver count watcher for the given location.
  /// This maintains persistent Firestore listeners and allows local refresh
  /// without creating new database reads.
  DriverCountWatcher createDriverCountWatcher(double lat, double lng) {
    return DriverCountWatcher(
      firestore: _firestore,
      lat: lat,
      lng: lng,
      staleThreshold: staleThreshold,
    );
  }

  /// Legacy method - creates new listeners each call (avoid if possible)
  /// Use createDriverCountWatcher() for optimized watching with refresh.
  @Deprecated('Use createDriverCountWatcher() for optimized watching')
  Stream<int> watchDriverCount(double lat, double lng) {
    final watcher = createDriverCountWatcher(lat, lng);
    return watcher.countStream;
  }

  /// Cleans up resources.
  void dispose() {
    stopHeartbeat();
    _presenceSubscription?.cancel();
  }
}

/// Watches driver count with persistent Firestore listeners.
/// Caches raw driver data locally and re-evaluates staleness on refresh.
/// This avoids creating new Firestore reads on every refresh cycle.
class DriverCountWatcher {
  final FirebaseFirestore _firestore;
  final double lat;
  final double lng;
  final Duration staleThreshold;

  final _countController = StreamController<int>.broadcast();
  final List<StreamSubscription> _subscriptions = [];

  // Cache of raw driver data per cell (includes potentially stale drivers)
  final Map<String, List<Map<String, dynamic>>> _cachedDriversPerCell = {};

  bool _isDisposed = false;
  bool _isInitialized = false;

  DriverCountWatcher({
    required FirebaseFirestore firestore,
    required this.lat,
    required this.lng,
    required this.staleThreshold,
  }) : _firestore = firestore {
    _initialize();
  }

  /// Stream of driver counts (emits on Firestore changes AND on refresh)
  Stream<int> get countStream => _countController.stream;

  /// Current count of fresh drivers
  int get currentCount => _calculateFreshCount();

  void _initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    final cellIds = GeoCellService.computeAllCellIds(lat, lng);

    // Conservative Firestore filter (1 hour) - reduces document count on initial load
    final conservativeCutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 1)),
    );

    print(
      '👀 Setting up persistent driver count listeners in ${cellIds.length} cells',
    );

    for (final cellId in cellIds) {
      final subscription = _firestore
          .collection('cells')
          .doc(cellId)
          .collection('presence')
          .where('role', isEqualTo: 'driver')
          .where('lastSeen', isGreaterThanOrEqualTo: conservativeCutoff)
          .snapshots()
          .listen(
            (snapshot) {
              // Cache raw driver data
              _cachedDriversPerCell[cellId] = snapshot.docs
                  .map((doc) => doc.data())
                  .toList();

              // Emit new count (filtered for freshness)
              _emitFreshCount();
            },
            onError: (error) {
              print('❌ Error watching drivers in cell $cellId: $error');
            },
          );

      _subscriptions.add(subscription);
    }
  }

  /// Calculates fresh driver count from cached data
  int _calculateFreshCount() {
    final now = DateTime.now();
    final preciseCutoff = now.subtract(staleThreshold);
    int total = 0;

    for (final entry in _cachedDriversPerCell.entries) {
      final freshCount = entry.value.where((data) {
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        if (lastSeen == null) return false;
        return lastSeen.isAfter(preciseCutoff);
      }).length;

      if (freshCount > 0) {
        print('✅ Cell ${entry.key}: $freshCount fresh driver(s)');
      }

      total += freshCount;
    }

    return total;
  }

  /// Emits the current fresh count to the stream
  void _emitFreshCount() {
    if (_isDisposed) return;
    _countController.add(_calculateFreshCount());
  }

  /// Refreshes the driver count by re-evaluating staleness locally.
  /// Does NOT create new Firestore reads - just re-filters cached data.
  void refresh() {
    if (_isDisposed) return;
    print('🔄 Refreshing driver count (local re-evaluation)');
    _emitFreshCount();
  }

  /// Disposes of all listeners and resources
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _cachedDriversPerCell.clear();
    _countController.close();

    print('🗑️ DriverCountWatcher disposed');
  }
}
