import 'package:launch_frontend/data/datasources/launch_remote_data_source.dart';
import 'package:launch_frontend/domain/entities/health_status.dart';
import 'package:launch_frontend/domain/entities/restaurant.dart';
import 'package:launch_frontend/domain/entities/user.dart';
import 'package:launch_frontend/domain/repositories/launch_repository.dart';

class LaunchRepositoryImpl implements LaunchRepository {
  final LaunchRemoteDataSource remoteDataSource;

  const LaunchRepositoryImpl(this.remoteDataSource);

  @override
  Future<HealthStatus> fetchHealthStatus() {
    return remoteDataSource.fetchHealthStatus();
  }

  @override
  Future<List<User>> fetchUsers() {
    return remoteDataSource.fetchUsers();
  }

  @override
  Future<List<Restaurant>> fetchRestaurants() {
    return remoteDataSource.fetchRestaurants();
  }
}
