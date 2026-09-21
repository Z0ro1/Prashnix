import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../profile/data/repositories/progress_repository.dart';

class CloudSyncRepository {
  final SupabaseClient _supabase;
  final ProgressRepository _progressRepository;
  final Connectivity _connectivity;

  static const String _pendingSyncKey = 'pending_cloud_sync_data';

  CloudSyncRepository({
    SupabaseClient? supabaseClient,
    ProgressRepository? progressRepository,
    Connectivity? connectivity,
  })  : _supabase = supabaseClient ?? SupabaseConfig.client,
        _progressRepository = progressRepository ?? ProgressRepository(),
        _connectivity = connectivity ?? Connectivity();

  Future<void> syncProgressToCloud({
    required int xp,
    required int streak,
    required int hearts,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Cannot sync without auth

    final syncData = {
      'total_xp': xp,
      'weekly_xp': xp, // Weekly would need proper logic on DB via RPC, passing same for now
      'streak_count': streak,
      'current_hearts': hearts,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final connectivityResult = await _connectivity.checkConnectivity();
    
    // Check if network is available
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // Offline: Cache the state locally to sync later
      await _progressRepository.saveLocalState(_pendingSyncKey, jsonEncode(syncData));
      return;
    }

    try {
      // Network available: Try syncing
      await _supabase.from('profiles').update(syncData).eq('id', user.id);
      
      // Successfully synced, clear any pending cache
      await _progressRepository.saveLocalState(_pendingSyncKey, '');
    } catch (e) {
      // Request failed (e.g. timeout): Cache the state to retry later
      await _progressRepository.saveLocalState(_pendingSyncKey, jsonEncode(syncData));
    }
  }

  Future<void> retryPendingSync() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    final pendingDataStr = await _progressRepository.getLocalState(_pendingSyncKey);
    if (pendingDataStr == null || pendingDataStr.isEmpty) return;

    try {
      final syncData = jsonDecode(pendingDataStr) as Map<String, dynamic>;
      await _supabase.from('profiles').update(syncData).eq('id', user.id);
      
      // Clear cache on success
      await _progressRepository.saveLocalState(_pendingSyncKey, '');
    } catch (_) {
      // Keep pending if it fails again
    }
  }

  Future<List<Map<String, dynamic>>> getDistrictLeaderboard(String district, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('district', district)
          .order('weekly_xp', ascending: false)
          .limit(limit);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('weekly_xp', ascending: false)
          .limit(limit);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
