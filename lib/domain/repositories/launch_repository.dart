import 'package:launch_frontend/domain/entities/health_status.dart';
import 'package:launch_frontend/domain/entities/restaurant.dart';
import 'package:launch_frontend/domain/entities/user.dart';

abstract class LaunchRepository {
  Future<HealthStatus> fetchHealthStatus();
  Future<List<User>> fetchUsers();
  Future<List<Restaurant>> fetchRestaurants();
}
