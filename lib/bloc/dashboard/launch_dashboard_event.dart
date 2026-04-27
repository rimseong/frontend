import 'package:equatable/equatable.dart';

abstract class LaunchDashboardEvent extends Equatable {
  const LaunchDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LaunchDashboardStarted extends LaunchDashboardEvent {
  const LaunchDashboardStarted();
}

class LaunchDashboardRefreshed extends LaunchDashboardEvent {
  const LaunchDashboardRefreshed();
}
