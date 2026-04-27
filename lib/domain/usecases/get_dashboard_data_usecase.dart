import 'package:launch_frontend/domain/entities/dashboard_data.dart';
import 'package:launch_frontend/domain/repositories/launch_repository.dart';

class GetDashboardDataUseCase {
  final LaunchRepository repository;

  const GetDashboardDataUseCase(this.repository);

  Future<DashboardData> call() async {
    final healthStatus = await repository.fetchHealthStatus();
    final users = await repository.fetchUsers();
    final restaurants = await repository.fetchRestaurants();

    return DashboardData(
      healthStatus: healthStatus,
      users: users,
      restaurants: restaurants,
    );
  }
}
