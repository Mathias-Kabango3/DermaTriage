/// SQLite-backed data model for a CHW user account.
///
/// Only bcrypt hashes are persisted — the raw password and the raw security
/// answer are never stored. [createdAt] is stored as an ISO-8601 string,
/// matching the `users` table schema.
class AppUser {
  final int? id; // null until inserted (autoincrement)
  final String username;
  final String passwordHash;
  final String securityQuestion;
  final String securityAnswerHash;
  final DateTime createdAt;

  const AppUser({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.securityQuestion,
    required this.securityAnswerHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      // Let SQLite assign the autoincrement id when inserting a new user.
      if (id != null) 'id': id,
      'username': username,
      'password_hash': passwordHash,
      'security_question': securityQuestion,
      'security_answer_hash': securityAnswerHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      securityQuestion: map['security_question'] as String,
      securityAnswerHash: map['security_answer_hash'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? securityQuestion,
    String? securityAnswerHash,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswerHash: securityAnswerHash ?? this.securityAnswerHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
