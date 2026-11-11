class DailyActivityRecord {
  final int lessonsCompleted;
  final int xpEarned;

  const DailyActivityRecord({
    this.lessonsCompleted = 0,
    this.xpEarned = 0,
  });

  Map<String, dynamic> toMap() => {
    'lessonsCompleted': lessonsCompleted,
    'xpEarned': xpEarned,
  };

  factory DailyActivityRecord.fromMap(Map<String, dynamic> map) => DailyActivityRecord(
    lessonsCompleted: (map['lessonsCompleted'] as num?)?.toInt() ?? 0,
    xpEarned: (map['xpEarned'] as num?)?.toInt() ?? 0,
  );
}

class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final int streakFreezes;
  final bool isFreezeEquipped;
  final Set<String> activeDates; // 'YYYY-MM-DD' in IST
  final Set<String> frozenDates; // 'YYYY-MM-DD' in IST
  final Map<String, DailyActivityRecord> dailyActivity;
  final String? lastActiveDate; // 'YYYY-MM-DD'

  const StreakInfo({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.streakFreezes = 2,
    this.isFreezeEquipped = true,
    this.activeDates = const {},
    this.frozenDates = const {},
    this.dailyActivity = const {},
    this.lastActiveDate,
  });

  bool isPracticedOn(String dateStr) => activeDates.contains(dateStr);
  bool isFrozenOn(String dateStr) => frozenDates.contains(dateStr);

  int get totalActiveDays => activeDates.length;

  DailyActivityRecord? getActivityFor(String dateStr) => dailyActivity[dateStr];

  StreakInfo copyWith({
    int? currentStreak,
    int? longestStreak,
    int? streakFreezes,
    bool? isFreezeEquipped,
    Set<String>? activeDates,
    Set<String>? frozenDates,
    Map<String, DailyActivityRecord>? dailyActivity,
    String? lastActiveDate,
  }) {
    return StreakInfo(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      isFreezeEquipped: isFreezeEquipped ?? this.isFreezeEquipped,
      activeDates: activeDates ?? this.activeDates,
      frozenDates: frozenDates ?? this.frozenDates,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}
