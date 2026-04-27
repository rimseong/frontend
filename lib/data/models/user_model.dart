import 'package:launch_frontend/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.dept,
    required super.employeeNo,
    required super.email,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      dept: json['dept'] as String?,
      employeeNo: (json['employee_no'] ?? '') as String,
      email: json['email'] as String?,
      role: (json['role'] ?? 'user') as String,
    );
  }
}
