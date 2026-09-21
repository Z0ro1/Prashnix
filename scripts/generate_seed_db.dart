import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() {
  final assetsDir = Directory(p.join(Directory.current.path, 'assets', 'database'));
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  final dbPath = p.join(assetsDir.path, 'spardha_questions.db');
  
  // Delete if exists for a fresh seed
  final dbFile = File(dbPath);
  if (dbFile.existsSync()) {
    dbFile.deleteSync();
  }

  final db = sqlite3.open(dbPath);

  print('Creating tables...');
  
  // Create Questions Table
  db.execute('''
    CREATE TABLE IF NOT EXISTS questions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject_tag TEXT NOT NULL,
      subtopic_tag TEXT,
      question_text TEXT NOT NULL,
      option_a TEXT NOT NULL,
      option_b TEXT NOT NULL,
      option_c TEXT NOT NULL,
      option_d TEXT NOT NULL,
      correct_option TEXT NOT NULL,
      explanation TEXT,
      pyq_year INTEGER,
      district_tag TEXT
    )
  ''');

  // Create Lessons Table
  db.execute('''
    CREATE TABLE IF NOT EXISTS lessons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      node_id INTEGER NOT NULL,
      lesson_order INTEGER NOT NULL,
      subject_tag TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0,
      high_score INTEGER DEFAULT 0,
      completed_at TEXT
    )
  ''');

  // Create Mistakes Table
  db.execute('''
    CREATE TABLE IF NOT EXISTS user_mistakes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL,
      user_answer TEXT NOT NULL,
      mistake_count INTEGER DEFAULT 1,
      is_cleared INTEGER DEFAULT 0,
      last_failed_at TEXT NOT NULL,
      FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
    )
  ''');

  // Create Progress Table
  db.execute('''
    CREATE TABLE IF NOT EXISTS offline_user_progress (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');

  print('Seeding questions...');
  
  final stmt = db.prepare('''
    INSERT INTO questions (
      subject_tag, subtopic_tag, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, pyq_year, district_tag
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''');

  final subjects = ['Marathi Grammar', 'Mathematics', 'Reasoning', 'GK'];
  int totalCount = 0;

  for (final subject in subjects) {
    // Generate 10 mock questions per subject for the demo
    for (int i = 1; i <= 10; i++) {
      stmt.execute([
        subject,
        'Topic $i',
        'Sample $subject question $i?',
        'Option A',
        'Option B',
        'Option C',
        'Option D',
        ['A', 'B', 'C', 'D'][i % 4], // Random correct option
        'This is the explanation for question $i.',
        2020 + (i % 4),
        'Pune'
      ]);
      totalCount++;
    }
  }

  stmt.dispose();
  db.dispose();

  print('Successfully generated seed DB with $totalCount questions at $dbPath');
}
