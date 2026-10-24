import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'db_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = join(documentsDirectory.path, DbConstants.databaseName);

    // Make sure the parent directory exists
    try {
      await Directory(dirname(dbPath)).create(recursive: true);
    } catch (_) {}

    // Open the database (this will trigger _onCreate to create empty tables)
    final db = await openDatabase(
      dbPath,
      version: DbConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return db;
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Execute creation scripts to ensure tables exist
    await db.execute(DbConstants.createQuestionsTable);
    await db.execute(DbConstants.createLessonsTable);
    await db.execute(DbConstants.createMistakesTable);
    await db.execute(DbConstants.createProgressTable);
    await db.execute(DbConstants.createSavedQuestionsTable);

    // Apply indexes
    await db.execute(DbConstants.indexQuestionsSubject);
    await db.execute(DbConstants.indexMistakesCleared);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(DbConstants.createSavedQuestionsTable);
    }
    if (oldVersion < 3) {
      // Safely delete only the locally cached questions, forcing a re-fetch from Supabase
      // without destroying user progress!
      await db.execute('DELETE FROM ${DbConstants.tableQuestions}');
    }
    if (oldVersion < 4) {
      // Version 4 removes ON DELETE CASCADE from mistakes and saved_questions.
      // SQLite requires recreating the tables to drop a foreign key.
      
      // 1. Rename old tables
      await db.execute('ALTER TABLE ${DbConstants.tableMistakes} RENAME TO old_mistakes');
      await db.execute('ALTER TABLE ${DbConstants.tableSavedQuestions} RENAME TO old_saved');
      
      // 2. Create new tables without foreign keys
      await db.execute(DbConstants.createMistakesTable);
      await db.execute(DbConstants.createSavedQuestionsTable);
      
      // 3. Copy data safely
      await db.execute('''
        INSERT INTO ${DbConstants.tableMistakes} 
        (id, question_id, user_answer, mistake_count, is_cleared, last_failed_at) 
        SELECT id, question_id, user_answer, mistake_count, is_cleared, last_failed_at 
        FROM old_mistakes
      ''');
      
      await db.execute('''
        INSERT INTO ${DbConstants.tableSavedQuestions} 
        (id, question_id, saved_at) 
        SELECT id, question_id, saved_at 
        FROM old_saved
      ''');
      
      // 4. Drop old tables
      await db.execute('DROP TABLE old_mistakes');
      await db.execute('DROP TABLE old_saved');
      
      // 5. Re-apply indexes
      await db.execute(DbConstants.indexMistakesCleared);
    }
    if (oldVersion < 5) {
      // Version 5 changes question IDs to TEXT (UUIDs). We must drop the tables to recreate them with TEXT schemas.
      await db.execute('DROP TABLE IF EXISTS ${DbConstants.tableMistakes}');
      await db.execute('DROP TABLE IF EXISTS ${DbConstants.tableSavedQuestions}');
      await db.execute('DROP TABLE IF EXISTS ${DbConstants.tableQuestions}');
      
      await db.execute(DbConstants.createQuestionsTable);
      await db.execute(DbConstants.createMistakesTable);
      await db.execute(DbConstants.createSavedQuestionsTable);
      
      await db.execute(DbConstants.indexQuestionsSubject);
      await db.execute(DbConstants.indexMistakesCleared);
    }
  }
}
