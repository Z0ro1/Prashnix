import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'db_constants.dart';
import '../constants/seed_data.dart';

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

    // Check if DB exists
    final exists = await databaseExists(dbPath);

    if (!exists) {
      // Make sure the parent directory exists
      try {
        await Directory(dirname(dbPath)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load('assets/database/${DbConstants.databaseName}');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    // Open the database
    final db = await openDatabase(
      dbPath,
      version: DbConstants.databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _seedFirstNodeQuestions(db);
    return db;
  }

  Future<void> _seedFirstNodeQuestions(Database db) async {
    final result = await db.query(
      DbConstants.tableQuestions,
      where: 'subject_tag = ?',
      whereArgs: ['First_Node_Demo'],
      limit: 1,
    );
    
    if (result.isEmpty) {
      final batch = db.batch();
      for (final q in SeedData.firstNodeQuestions) {
        batch.insert(
          DbConstants.tableQuestions,
          {
            'subject_tag': 'First_Node_Demo',
            'subtopic_tag': q['category'],
            'question_text': q['question'],
            'option_a': q['options']['A'],
            'option_b': q['options']['B'],
            'option_c': q['options']['C'],
            'option_d': q['options']['D'],
            'correct_option': q['correct_ans'],
            'explanation': q['explanation'],
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Note: Since we are copying a pre-populated DB, onCreate might not trigger
    // unless the asset DB is empty or missing tables.
    // We execute creation scripts just in case to ensure tables exist.
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
  }
}
