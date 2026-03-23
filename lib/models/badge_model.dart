enum BadgeTier { bronze, silver, gold, diamond }

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.milestoneDays,
    required this.tier,
    this.unlockedAt,
    this.unlockedByHabitId,
    this.unlockedByHabitName,
  });

  final String id;
  final String title;
  final String description;
  final int milestoneDays;
  final BadgeTier tier;

  final DateTime? unlockedAt;
  final String? unlockedByHabitId;
  final String? unlockedByHabitName;

  bool get isUnlocked => unlockedAt != null;

  BadgeModel copyWith({
    String? id,
    String? title,
    String? description,
    int? milestoneDays,
    BadgeTier? tier,
    DateTime? unlockedAt,
    bool clearUnlockedAt = false,
    String? unlockedByHabitId,
    bool clearUnlockedByHabitId = false,
    String? unlockedByHabitName,
    bool clearUnlockedByHabitName = false,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      milestoneDays: milestoneDays ?? this.milestoneDays,
      tier: tier ?? this.tier,
      unlockedAt: clearUnlockedAt ? null : (unlockedAt ?? this.unlockedAt),
      unlockedByHabitId: clearUnlockedByHabitId
          ? null
          : (unlockedByHabitId ?? this.unlockedByHabitId),
      unlockedByHabitName: clearUnlockedByHabitName
          ? null
          : (unlockedByHabitName ?? this.unlockedByHabitName),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'milestoneDays': milestoneDays,
      'tier': tier.name,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'unlockedByHabitId': unlockedByHabitId,
      'unlockedByHabitName': unlockedByHabitName,
    };
  }

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    final tierName = (json['tier'] as String?) ?? BadgeTier.bronze.name;
    return BadgeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      milestoneDays: json['milestoneDays'] as int,
      tier: BadgeTier.values.firstWhere(
        (value) => value.name == tierName,
        orElse: () => BadgeTier.bronze,
      ),
      unlockedAt: json['unlockedAt'] == null
          ? null
          : DateTime.parse(json['unlockedAt'] as String),
      unlockedByHabitId: json['unlockedByHabitId'] as String?,
      unlockedByHabitName: json['unlockedByHabitName'] as String?,
    );
  }

  static List<BadgeModel> defaultBadges() {
    return const <BadgeModel>[
      BadgeModel(
        id: 'badge_bronze_7',
        title: 'Khởi Đầu Hoàn Hảo',
        description: 'Duy trì thói quen liên tiếp 7 ngày.',
        milestoneDays: 7,
        tier: BadgeTier.bronze,
      ),
      BadgeModel(
        id: 'badge_silver_21',
        title: 'Thói Quen Hình Thành',
        description: 'Duy trì thói quen liên tiếp 21 ngày.',
        milestoneDays: 21,
        tier: BadgeTier.silver,
      ),
      BadgeModel(
        id: 'badge_gold_50',
        title: 'Kiên Trì Bền Bỉ',
        description: 'Duy trì thói quen liên tiếp 50 ngày.',
        milestoneDays: 50,
        tier: BadgeTier.gold,
      ),
      BadgeModel(
        id: 'badge_diamond_100',
        title: 'Kỷ Luật Thép',
        description: 'Duy trì thói quen liên tiếp 100 ngày.',
        milestoneDays: 100,
        tier: BadgeTier.diamond,
      ),
    ];
  }
}
