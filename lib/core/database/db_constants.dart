class DbConstants {
  DbConstants._();

  static const String databaseName = 'spardha_questions.db';
  static const int databaseVersion = 2;

  // Table Names
  static const String tableQuestions = 'questions';
  static const String tableLessons = 'lessons';
  static const String tableMistakes = 'user_mistakes';
  static const String tableProgress = 'offline_user_progress';
  static const String tableSavedQuestions = 'saved_questions';

  // Schema Definitions
  static const String createQuestionsTable = '''
    CREATE TABLE IF NOT EXISTS $tableQuestions (
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
  ''';

  static const String createLessonsTable = '''
    CREATE TABLE IF NOT EXISTS $tableLessons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      node_id INTEGER NOT NULL,
      lesson_order INTEGER NOT NULL,
      subject_tag TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0,
      high_score INTEGER DEFAULT 0,
      completed_at TEXT
    )
  ''';

  static const String createMistakesTable = '''
    CREATE TABLE IF NOT EXISTS $tableMistakes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL,
      user_answer TEXT NOT NULL,
      mistake_count INTEGER DEFAULT 1,
      is_cleared INTEGER DEFAULT 0,
      last_failed_at TEXT NOT NULL,
      FOREIGN KEY (question_id) REFERENCES $tableQuestions (id) ON DELETE CASCADE
    )
  ''';

  static const String createProgressTable = '''
    CREATE TABLE IF NOT EXISTS $tableProgress (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static const String createSavedQuestionsTable = '''
    CREATE TABLE IF NOT EXISTS $tableSavedQuestions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL UNIQUE,
      saved_at TEXT NOT NULL,
      FOREIGN KEY (question_id) REFERENCES $tableQuestions (id) ON DELETE CASCADE
    )
  ''';

  // Index Definitions
  static const String indexQuestionsSubject = '''
    CREATE INDEX IF NOT EXISTS idx_questions_subject ON $tableQuestions(subject_tag)
  ''';

  static const String indexMistakesCleared = '''
    CREATE INDEX IF NOT EXISTS idx_mistakes_cleared ON $tableMistakes(is_cleared)
  ''';
}
