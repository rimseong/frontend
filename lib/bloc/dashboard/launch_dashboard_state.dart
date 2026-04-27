import 'package:equatable/equatable.dart';
import 'package:launch_frontend/domain/entities/health_status.dart';
import 'package:launch_frontend/domain/entities/restaurant.dart';
import 'package:launch_frontend/domain/entities/user.dart';

enum LaunchDashboardStatus { initial, loading, success, failure }

class LaunchDashboardState extends Equatable {
  final LaunchDashboardStatus status;
  final HealthStatus healthStatus;
  final List<User> users;
  final List<Restaurant> restaurants;
  final String? errorMessage;

  const LaunchDashboardState({
    this.status = LaunchDashboardStatus.initial,
    this.healthStatus = const HealthStatus(status: 'loading'),
    this.users = const [],
    this.restaurants = const [],
    this.errorMessage,
  });

  bool get isLoading => status == LaunchDashboardStatus.loading;

  LaunchDashboardState copyWith({
    LaunchDashboardStatus? status,
    HealthStatus? healthStatus,
    List<User>? users,
    List<Restaurant>? restaurants,
    String? errorMessage,
  }) {
    return LaunchDashboardState(
      status: status ?? this.status,
      healthStatus: healthStatus ?? this.healthStatus,
      users: users ?? this.users,
      restaurants: restaurants ?? this.restaurants,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, healthStatus, users, restaurants, errorMessage];
}
