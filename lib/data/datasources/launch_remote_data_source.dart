import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:launch_frontend/core/constants/app_constants.dart';
import 'package:launch_frontend/data/models/health_status_model.dart';
import 'package:launch_frontend/data/models/restaurant_model.dart';
import 'package:launch_frontend/data/models/user_model.dart';

abstract class LaunchRemoteDataSource {
  Future<HealthStatusModel> fetchHealthStatus();
  Future<List<UserModel>> fetchUsers();
  Future<List<RestaurantModel>> fetchRestaurants();
}

class LaunchRemoteDataSourceImpl implements LaunchRemoteDataSource {
  final http.Client client;

  const LaunchRemoteDataSourceImpl(this.client);

  @override
  Future<HealthStatusModel> fetchHealthStatus() async {
    final response = await client
        .get(Uri.parse('${AppConstants.apiBaseUrl}/health'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Failed to load health status');
    }

    return HealthStatusModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<List<UserModel>> fetchUsers() async {
    final response = await client
        .get(Uri.parse('${AppConstants.apiBaseUrl}/users'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }

    final List<dynamic> rawList = jsonDecode(response.body) as List<dynamic>;
    return rawList
        .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<RestaurantModel>> fetchRestaurants() async {
    final response = await client
        .get(Uri.parse('${AppConstants.apiBaseUrl}/restaurants'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Failed to load restaurants');
    }

    final List<dynamic> rawList = jsonDecode(response.body) as List<dynamic>;
    return rawList
        .map((item) => RestaurantModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
