import 'package:launch_frontend/domain/entities/health_status.dart';
import 'package:launch_frontend/domain/entities/restaurant.dart';
import 'package:launch_frontend/domain/entities/user.dart';

class DashboardData {
  final HealthStatus healthStatus;
  final List<User> users;
  final List<Restaurant> restaurants;

  const DashboardData({
    required this.healthStatus,
    required this.users,
    required this.restaurants,
  });
}
