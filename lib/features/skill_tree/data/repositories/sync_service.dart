import 'package:flutter/foundation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../features/profile/data/repositories/progress_repository.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  final ProgressRepository _progressRepo;
  
  SyncService({ProgressRepository? progressRepo}) 
      : _progressRepo = progressRepo ?? ProgressRepository();

  /// Pushes local node progress up to Supabase.
  /// If offline, it fails silently, but the local progress remains safe.
  Future<void> pushNodeProgress(String nodeId, int completedLessons, bool isCompleted) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Save to Local SQLite (Instantly updates UI & works offline)
    await _progressRepo.saveLocalState('progress_$nodeId', completedLessons.toString());
    await _progressRepo.saveLocalState('status_$nodeId', isCompleted ? '1' : '0');
    await _progressRepo.saveLocalState('progress_node_$nodeId', completedLessons.toString());
    await _progressRepo.saveLocalState('status_node_$nodeId', isCompleted ? '1' : '0');

    // 2. Fire and forget to Supabase (Background Sync)
    try {
      await SupabaseConfig.client.from('user_progress').upsert({
        'user_id': userId,
        'node_id': nodeId,
        'completed_lessons': completedLessons,
        'is_completed': isCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('SyncService: Failed to push $nodeId to cloud (Offline mode). $e');
      // In a full production app, we would add this to an "offline_sync_queue" SQLite table here.
    }
  }

  /// Pulls the entire progress history from Supabase and saves it locally.
  /// Used on App Startup or when logging into a new device.
  Future<void> pullProgress() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final List<dynamic> serverProgress = await SupabaseConfig.client
          .from('user_progress')
          .select()
          .eq('user_id', userId);

      // Overwrite local SQLite with cloud truth
      for (final row in serverProgress) {
        final nodeId = row['node_id'] as String;
        final completedLessons = row['completed_lessons'] as int;
        final isCompleted = row['is_completed'] as bool;

        await _progressRepo.saveLocalState('progress_$nodeId', completedLessons.toString());
        await _progressRepo.saveLocalState('status_$nodeId', isCompleted ? '1' : '0');
        await _progressRepo.saveLocalState('progress_node_$nodeId', completedLessons.toString());
        await _progressRepo.saveLocalState('status_node_$nodeId', isCompleted ? '1' : '0');
      }

      // Pull mistakes
      final List<dynamic> serverMistakes = await SupabaseConfig.client
          .from('user_mistakes')
          .select()
          .eq('user_id', userId);
      
      final db = await DatabaseService().database;
      for (final row in serverMistakes) {
        final qId = row['question_id'] as String;
        await db.insert(
          DbConstants.tableMistakes,
          {
            'id': row['id'],
            'question_id': qId,
            'user_answer': row['user_answer'] ?? '',
            'mistake_count': row['mistake_count'] ?? 1,
            'is_cleared': (row['is_cleared'] == true) ? 1 : 0,
            'last_failed_at': row['last_failed_at'] ?? DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Pull saved questions
      final List<dynamic> serverSaved = await SupabaseConfig.client
          .from('saved_questions')
          .select()
          .eq('user_id', userId);
          
      for (final row in serverSaved) {
        final qId = row['question_id'] as String;
        await db.insert(
          DbConstants.tableSavedQuestions,
          {
            'id': row['id'],
            'question_id': qId,
            'saved_at': row['saved_at'] ?? DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('SyncService: Failed to pull progress (Offline mode). $e');
    }
  }
}
