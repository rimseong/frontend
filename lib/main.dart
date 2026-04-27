import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:launch_frontend/app.dart';
import 'package:launch_frontend/bloc/dashboard/launch_dashboard_bloc.dart';
import 'package:launch_frontend/data/datasources/launch_remote_data_source.dart';
import 'package:launch_frontend/data/repositories/launch_repository_impl.dart';
import 'package:launch_frontend/domain/usecases/get_dashboard_data_usecase.dart';

void main() {
  final client = http.Client();
  final remoteDataSource = LaunchRemoteDataSourceImpl(client);
  final repository = LaunchRepositoryImpl(remoteDataSource);
  final getDashboardDataUseCase = GetDashboardDataUseCase(repository);

  runApp(
    BlocProvider(
      create: (_) => LaunchDashboardBloc(getDashboardDataUseCase),
      child: const LaunchApp(),
    ),
  );
}
