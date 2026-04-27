import 'package:launch_frontend/domain/entities/health_status.dart';

class HealthStatusModel extends HealthStatus {
  const HealthStatusModel({
    required super.status,
    super.message,
  });

  factory HealthStatusModel.fromJson(Map<String, dynamic> json) {
    return HealthStatusModel(
      status: (json['status'] ?? 'error') as String,
      message: json['message'] as String?,
    );
  }
}
