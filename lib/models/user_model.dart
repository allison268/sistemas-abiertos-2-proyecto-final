class UserModel {
  final String username;
  final String password;
  final int unlockedLevel;
  final Map<int, int> bestScores;

  UserModel({
    required this.username,
    required this.password,
    this.unlockedLevel = 1,
    Map<int, int>? bestScores,
  }) : bestScores = bestScores ?? {};

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'unlockedLevel': unlockedLevel,
      'bestScores': bestScores.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final bestScoresRaw = json['bestScores'] as Map<String, dynamic>? ?? {};
    final bestScores = bestScoresRaw.map(
      (k, v) => MapEntry(int.parse(k), v as int),
    );
    return UserModel(
      username: json['username'] as String,
      password: json['password'] as String,
      unlockedLevel: json['unlockedLevel'] as int? ?? 1,
      bestScores: bestScores,
    );
  }

  UserModel copyWith({int? unlockedLevel, Map<int, int>? bestScores}) {
    return UserModel(
      username: username,
      password: password,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      bestScores: bestScores ?? this.bestScores,
    );
  }
}
