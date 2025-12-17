import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'geo_cell_service.dart';

/// Status of a ride request.
enum RequestStatus { open, assigned, cancelled, completed }

/// Location data for pickup/dropoff.
class LocationPoint {
  final double lat;
  final double lng;
  final String? address; // Geocoded address name

  const LocationPoint({required this.lat, required this.lng, this.address});

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'lat': lat, 'lng': lng};
    if (address != null) map['address'] = address;
    return map;
  }
}

/// Ride request data model.
class RideRequest {
  final String requestId;
  final String createdByUid;
  final LocationPoint pickup;
  final LocationPoint? dropoff;
  final RequestStatus status;
  final String? assignedDriverUid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String cellId;
  final DateTime expiresAt;

  // Driver real-time location (updated during "assigned" status)
  final double? driverLat;
  final double? driverLng;
  final DateTime? driverLocationUpdatedAt;

  // Client heartbeat - updated every 30s while client is actively waiting
  final DateTime? lastHeartbeat;

  // Display names for UI
  final String? clientName;
  final String? driverName;

  /// Stale threshold for requests (3 minutes)
  static const Duration staleThreshold = Duration(minutes: 3);

  RideRequest({
    required this.requestId,
    required this.createdByUid,
    required this.pickup,
    this.dropoff,
    required this.status,
    this.assignedDriverUid,
    required this.createdAt,
    required this.updatedAt,
    required this.cellId,
    required this.expiresAt,
    this.driverLat,
    this.driverLng,
    this.driverLocationUpdatedAt,
    this.lastHeartbeat,
    this.clientName,
    this.driverName,
  });

  /// Returns true if the request is fresh (heartbeat within stale threshold)
  bool get isFresh {
    if (status != RequestStatus.open)
      return true; // Assigned/completed are always valid
    final heartbeat = lastHeartbeat ?? createdAt;
    return DateTime.now().difference(heartbeat) < staleThreshold;
  }

  factory RideRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideRequest(
      requestId: data['requestId'] ?? doc.id,
      createdByUid: data['createdByUid'] ?? '',
      pickup: LocationPoint.fromMap(data['pickup'] as Map<String, dynamic>),
      dropoff: data['dropoff'] != null
          ? LocationPoint.fromMap(data['dropoff'] as Map<String, dynamic>)
          : null,
      status: _parseStatus(data['status']),
      assignedDriverUid: data['assignedDriverUid'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cellId: data['cellId'] ?? '',
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      driverLat: (data['driverLat'] as num?)?.toDouble(),
      driverLng: (data['driverLng'] as num?)?.toDouble(),
      driverLocationUpdatedAt: (data['driverLocationUpdatedAt'] as Timestamp?)
          ?.toDate(),
      lastHeartbeat: (data['lastHeartbeat'] as Timestamp?)?.toDate(),
      clientName: data['clientName'] as String?,
      driverName: data['driverName'] as String?,
    );
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'open':
        return RequestStatus.open;
      case 'assigned':
        return RequestStatus.assigned;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'completed':
        return RequestStatus.completed;
      default:
        return RequestStatus.open;
    }
  }

  static String _statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.open:
        return 'open';
      case RequestStatus.assigned:
        return 'assigned';
      case RequestStatus.cancelled:
        return 'cancelled';
      case RequestStatus.completed:
        return 'completed';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'createdByUid': createdByUid,
      'pickup': pickup.toMap(),
      'dropoff': dropoff?.toMap(),
      'status': _statusToString(status),
      'assignedDriverUid': assignedDriverUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cellId': cellId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'lastHeartbeat': FieldValue.serverTimestamp(), // Initial heartbeat
      if (clientName != null) 'clientName': clientName,
      if (driverName != null) 'driverName': driverName,
    };
  }

  /// Duration since creation.
  Duration get age => DateTime.now().difference(createdAt);

  /// Human-readable age string.
  String get ageString {
    final mins = age.inMinutes;
    if (mins < 1) return 'Ahora';
    if (mins < 60) return 'Hace $mins min';
    final hours = age.inHours;
    if (hours < 24) return 'Hace $hours h';
    return 'Hace ${age.inDays} días';
  }
}

/// Service for managing ride requests.
class RequestService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Request TTL (24 hours)
  static const Duration requestTtl = Duration(hours: 24);

  RequestService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Gets the current user ID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Gets the Firestore reference for a request document.
  DocumentReference _requestRef(String cellId, String requestId) {
    return _firestore
        .collection('cells')
        .doc(cellId)
        .collection('requests')
        .doc(requestId);
  }

  /// Creates a new ride request.
  Future<RideRequest?> createRequest({
    required double pickupLat,
    required double pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? pickupAddress,
    String? dropoffAddress,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      print('⚠️ RequestService: No authenticated user');
      return null;
    }

    final cellId = GeoCellService.computeCellIdFromCoords(pickupLat, pickupLng);
    final requestId = _firestore
        .collection('cells')
        .doc()
        .id; // Generate unique ID

    print('📝 Creating request in cell: $cellId');

    final request = RideRequest(
      requestId: requestId,
      createdByUid: uid,
      pickup: LocationPoint(
        lat: pickupLat,
        lng: pickupLng,
        address: pickupAddress,
      ),
      dropoff: dropoffLat != null && dropoffLng != null
          ? LocationPoint(
              lat: dropoffLat,
              lng: dropoffLng,
              address: dropoffAddress,
            )
          : null,
      status: RequestStatus.open,
      assignedDriverUid: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      cellId: cellId,
      expiresAt: DateTime.now().add(requestTtl),
    );

    await _requestRef(cellId, requestId).set(request.toFirestore());

    print('✅ Request created: $requestId');
    return request;
  }

  /// Cancels a request (only by creator).
  Future<void> cancelRequest(String cellId, String requestId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _requestRef(cellId, requestId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('❌ Request cancelled: $requestId');
  }

  /// Assigns a driver to a request.
  Future<void> assignDriver(
    String cellId,
    String requestId,
    String driverUid,
  ) async {
    // Fetch current driver's name from Firestore users collection
    String driverName = 'Conductor';
    try {
      final userDoc = await _firestore.collection('users').doc(driverUid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final name = data?['name'] as String?;
        if (name != null && name.isNotEmpty) {
          driverName = name;
        }
      }
    } catch (e) {
      print('⚠️ Could not fetch driver name: $e');
    }

    await _requestRef(cellId, requestId).update({
      'status': 'assigned',
      'assignedDriverUid': driverUid,
      'driverName': driverName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('🚴 Driver $driverName assigned to request: $requestId');
  }

  /// Completes a request.
  Future<void> completeRequest(String cellId, String requestId) async {
    await _requestRef(cellId, requestId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Request completed: $requestId');
  }

  /// Updates the heartbeat timestamp for a request.
  /// Called periodically by client to indicate they are still waiting.
  Future<void> updateHeartbeat(String cellId, String requestId) async {
    try {
      await _requestRef(
        cellId,
        requestId,
      ).update({'lastHeartbeat': FieldValue.serverTimestamp()});
      print('💓 Request heartbeat: $requestId');
    } catch (e) {
      print('⚠️ Failed to update heartbeat: $e');
    }
  }

  /// Updates driver's real-time location for a request.
  /// Called by conductor app during assigned/arriving status.
  Future<void> updateDriverLocation(
    String cellId,
    String requestId,
    double lat,
    double lng,
  ) async {
    await _requestRef(cellId, requestId).update({
      'driverLat': lat,
      'driverLng': lng,
      'driverLocationUpdatedAt': FieldValue.serverTimestamp(),
    });

    print('📍 Driver location updated for request: $requestId');
  }

  /// Watches a single request document for real-time updates.
  /// Used by client app to track driver location and status changes.
  Stream<RideRequest?> watchRequest(String cellId, String requestId) {
    return _requestRef(cellId, requestId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return RideRequest.fromFirestore(snapshot);
    });
  }

  /// Watches open requests in a single cell.
  Stream<List<RideRequest>> watchOpenRequestsInCell(String cellId) {
    return _firestore
        .collection('cells')
        .doc(cellId)
        .collection('requests')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RideRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Watches open requests in current cell and optionally neighbors.
  /// Starts with just current cell, then expands after delay.
  Stream<List<RideRequest>> watchOpenRequests({
    required double lat,
    required double lng,
    bool includeNeighbors = false,
  }) {
    final currentCellId = GeoCellService.computeCellIdFromCoords(lat, lng);

    if (!includeNeighbors) {
      return watchOpenRequestsInCell(currentCellId);
    }

    // Include all 9 cells
    final cellIds = GeoCellService.computeAllCellIds(lat, lng);

    print('👀 Watching requests in ${cellIds.length} cells');

    final streams = cellIds.map(watchOpenRequestsInCell).toList();
    return _combineListStreams(streams);
  }

  /// Watches open requests with delayed expansion to neighbors.
  /// Initially watches only current cell, expands to 9 cells after delay.
  Stream<List<RideRequest>> watchOpenRequestsWithExpansion({
    required double lat,
    required double lng,
    Duration expandDelay = const Duration(seconds: 20),
  }) {
    final controller = StreamController<List<RideRequest>>.broadcast();
    StreamSubscription<List<RideRequest>>? currentSubscription;
    Timer? expansionTimer;
    bool expanded = false;

    void subscribeToCurrentOnly() {
      currentSubscription?.cancel();
      currentSubscription =
          watchOpenRequests(lat: lat, lng: lng, includeNeighbors: false).listen(
            (requests) {
              controller.add(requests);
            },
          );
    }

    void subscribeToAll() {
      currentSubscription?.cancel();
      currentSubscription =
          watchOpenRequests(lat: lat, lng: lng, includeNeighbors: true).listen((
            requests,
          ) {
            controller.add(requests);
          });
      expanded = true;
      print('🔄 Expanded to watch 9 cells');
    }

    // Start with current cell only
    subscribeToCurrentOnly();

    // Set timer to expand
    expansionTimer = Timer(expandDelay, () {
      if (!expanded && !controller.isClosed) {
        subscribeToAll();
      }
    });

    controller.onCancel = () {
      currentSubscription?.cancel();
      expansionTimer?.cancel();
    };

    return controller.stream;
  }

  /// Gets requests created by current user.
  Stream<List<RideRequest>> watchMyRequests() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    // Note: This requires querying across all cells, which is inefficient
    // In production, store user's active request reference in /users/{uid}
    // For now, we'll use collectionGroup query
    return _firestore
        .collectionGroup('requests')
        .where('createdByUid', isEqualTo: uid)
        .where('status', whereIn: ['open', 'assigned'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RideRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Combines multiple list streams into a single flattened list.
  Stream<List<RideRequest>> _combineListStreams(
    List<Stream<List<RideRequest>>> streams,
  ) {
    if (streams.isEmpty) return Stream.value([]);
    if (streams.length == 1) return streams.first;

    final controller = StreamController<List<RideRequest>>.broadcast();
    final lists = List<List<RideRequest>>.filled(streams.length, []);
    final subscriptions = <StreamSubscription<List<RideRequest>>>[];

    for (var i = 0; i < streams.length; i++) {
      final index = i;
      subscriptions.add(
        streams[i].listen((list) {
          lists[index] = list;
          // Remove duplicates by requestId
          final combined = <String, RideRequest>{};
          for (final l in lists) {
            for (final req in l) {
              combined[req.requestId] = req;
            }
          }
          // Sort by createdAt descending
          final sorted = combined.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          controller.add(sorted);
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
}
