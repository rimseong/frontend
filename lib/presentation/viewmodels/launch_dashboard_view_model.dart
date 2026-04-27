import 'package:flutter/foundation.dart';
import 'package:launch_frontend/domain/entities/health_status.dart';
import 'package:launch_frontend/domain/entities/restaurant.dart';
import 'package:launch_frontend/domain/entities/user.dart';
import 'package:launch_frontend/domain/usecases/get_dashboard_data_usecase.dart';

class LaunchDashboardViewModel extends ChangeNotifier {
  final GetDashboardDataUseCase getDashboardDataUseCase;

  LaunchDashboardViewModel(this.getDashboardDataUseCase);

  bool isLoading = false;
  String? errorMessage;
  HealthStatus healthStatus = const HealthStatus(status: 'loading');
  List<User> users = const [];
  List<Restaurant> restaurants = const [];

  Future<void> loadDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await getDashboardDataUseCase();
      healthStatus = data.healthStatus;
      users = data.users;
      restaurants = data.restaurants;
    } catch (e) {
      healthStatus = const HealthStatus(status: 'error');
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
