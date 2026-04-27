import 'package:launch_frontend/domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.isActive,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      isActive: (json['is_active'] ?? false) as bool,
    );
  }
}
