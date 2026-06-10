enum UserRole { admin, worker, driver, upakovchik }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:       return 'Admin';
      case UserRole.worker:      return 'Ishchi';
      case UserRole.driver:      return 'Haydovchi';
      case UserRole.upakovchik:  return 'Upakovchik';
    }
  }
}

class UserModel {
  final String id;
  final String login;
  final String password;
  final String name;
  final UserRole role;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.login,
    required this.password,
    required this.name,
    required this.role,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'login': login,
        'password': password,
        'name': name,
        'role': role.name,
        'is_active': isActive ? 1 : 0,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'].toString(),
        login: map['login'] ?? '',
        password: map['password'] ?? '',
        name: map['name'] ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == (map['role'] ?? 'worker'),
          orElse: () => UserRole.worker,
        ),
        isActive: (map['is_active'] ?? 1) == 1,
      );

  // Keep for fallback / offline use
  static const List<UserModel> hardcodedUsers = [
    UserModel(
      id: '1',
      login: 'admin',
      password: 'admin123',
      name: 'Administrator',
      role: UserRole.admin,
    ),
    UserModel(
      id: '2',
      login: 'usta1',
      password: '1234',
      name: 'Usta Alisher',
      role: UserRole.worker,
    ),
    UserModel(
      id: '3',
      login: 'usta2',
      password: '1234',
      name: 'Usta Bobur',
      role: UserRole.worker,
    ),
    UserModel(
      id: '4',
      login: 'usta3',
      password: '1234',
      name: 'Usta Jasur',
      role: UserRole.worker,
    ),
    UserModel(
      id: '5',
      login: 'usta4',
      password: '1234',
      name: 'Usta Sardor',
      role: UserRole.worker,
    ),
    UserModel(
      id: '6',
      login: 'haydovchi1',
      password: '1234',
      name: 'Haydovchi Ulugbek',
      role: UserRole.driver,
    ),
    UserModel(
      id: '7',
      login: 'haydovchi2',
      password: '1234',
      name: 'Haydovchi Mirzo',
      role: UserRole.driver,
    ),
  ];
}
