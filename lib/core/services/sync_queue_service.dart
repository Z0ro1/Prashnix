import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../../features/leaderboard/data/repositories/cloud_sync_repository.dart';

class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final CloudSyncRepository _cloudSyncRepo = CloudSyncRepository();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        _drainQueue();
      }
    });
    
    // Also try immediately on startup if online
    _drainQueue();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _drainQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (kDebugMode) {
        print('[SyncQueueService] Network restored. Draining offline pending queue...');
      }
      await _cloudSyncRepo.retryPendingSync();
    } catch (e) {
      if (kDebugMode) {
        print('[SyncQueueService] Failed to drain queue: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }
}
