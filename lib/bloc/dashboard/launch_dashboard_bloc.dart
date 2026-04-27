import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launch_frontend/bloc/dashboard/launch_dashboard_event.dart';
import 'package:launch_frontend/bloc/dashboard/launch_dashboard_state.dart';
import 'package:launch_frontend/domain/entities/health_status.dart';
import 'package:launch_frontend/domain/usecases/get_dashboard_data_usecase.dart';

class LaunchDashboardBloc extends Bloc<LaunchDashboardEvent, LaunchDashboardState> {
  final GetDashboardDataUseCase getDashboardDataUseCase;

  LaunchDashboardBloc(this.getDashboardDataUseCase) : super(const LaunchDashboardState()) {
    on<LaunchDashboardStarted>(_onStarted);
    on<LaunchDashboardRefreshed>(_onRefreshed);
  }

  Future<void> _onStarted(
    LaunchDashboardStarted event,
    Emitter<LaunchDashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }

  Future<void> _onRefreshed(
    LaunchDashboardRefreshed event,
    Emitter<LaunchDashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }

  Future<void> _loadDashboard(Emitter<LaunchDashboardState> emit) async {
    emit(state.copyWith(status: LaunchDashboardStatus.loading, errorMessage: null));

    try {
      final data = await getDashboardDataUseCase();
      emit(
        state.copyWith(
          status: LaunchDashboardStatus.success,
          healthStatus: data.healthStatus,
          users: data.users,
          restaurants: data.restaurants,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LaunchDashboardStatus.failure,
          healthStatus: const HealthStatus(status: 'error'),
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
