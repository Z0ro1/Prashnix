import sqlite3
import json
import os

db_path = 'assets/database/spardha_questions.db'
os.makedirs(os.path.dirname(db_path), exist_ok=True)

# Remove old db if it exists
if os.path.exists(db_path):
    os.remove(db_path)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create Tables
cursor.execute('''
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
''')

cursor.execute('''
    CREATE TABLE IF NOT EXISTS lessons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      node_id INTEGER NOT NULL,
      lesson_order INTEGER NOT NULL,
      subject_tag TEXT NOT NULL,
      is_completed INTEGER DEFAULT 0,
      high_score INTEGER DEFAULT 0,
      completed_at TEXT
    )
''')

cursor.execute('''
    CREATE TABLE IF NOT EXISTS user_mistakes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question_id INTEGER NOT NULL,
      user_answer TEXT NOT NULL,
      mistake_count INTEGER DEFAULT 1,
      is_cleared INTEGER DEFAULT 0,
      last_failed_at TEXT NOT NULL,
      FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
    )
''')

cursor.execute('''
    CREATE TABLE IF NOT EXISTS offline_user_progress (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
''')

import random

# Load questions
with open('lib/core/database/questions/questions_fixed.json', 'r', encoding='utf-8') as f:
    questions = json.load(f)

# Fully randomize the entire bank
random.shuffle(questions)

# Group questions into 6 nodes
nodes_count = 6
questions_per_node = len(questions) // nodes_count

node_id = 0
for i, q in enumerate(questions):
    if i > 0 and i % questions_per_node == 0 and node_id < nodes_count - 1:
        node_id += 1
        
    if i % questions_per_node == 0 and node_id < nodes_count:
        # Create a new lesson/node entry
        subject_tag = f"node_{node_id}"
        cursor.execute('''
            INSERT INTO lessons (node_id, lesson_order, subject_tag) 
            VALUES (?, ?, ?)
        ''', (node_id, node_id, subject_tag))
    
    subject_tag = f"node_{node_id}"
    
    opts = q.get('options', [])
    opt_a = opts[0] if len(opts) > 0 else "N/A"
    opt_b = opts[1] if len(opts) > 1 else "N/A"
    opt_c = opts[2] if len(opts) > 2 else "N/A"
    opt_d = opts[3] if len(opts) > 3 else "N/A"
    
    correct_text = q.get('correct_answer', '')
    correct_option_letter = 'A'
    if opt_a == correct_text: correct_option_letter = 'A'
    elif opt_b == correct_text: correct_option_letter = 'B'
    elif opt_c == correct_text: correct_option_letter = 'C'
    elif opt_d == correct_text: correct_option_letter = 'D'
    
    cursor.execute('''
        INSERT INTO questions (
            subject_tag, subtopic_tag, question_text, 
            option_a, option_b, option_c, option_d, 
            correct_option, explanation
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        subject_tag, 
        "General", 
        q.get('question', ''), 
        opt_a, opt_b, opt_c, opt_d, 
        correct_option_letter, 
        q.get('explanation', '')
    ))

conn.commit()
conn.close()
print(f"Successfully seeded {len(questions)} questions into {node_id} nodes.")
