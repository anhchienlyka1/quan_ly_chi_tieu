/// Model representing a user.
class UserModel {
  final String? id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final double? monthlyBudget;

  const UserModel({
    this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.monthlyBudget,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    double? monthlyBudget,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'monthlyBudget': monthlyBudget,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble(),
    );
  }
}
