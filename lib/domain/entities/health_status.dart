class HealthStatus {
  final String status;
  final String? message;

  const HealthStatus({
    required this.status,
    this.message,
  });

  bool get isHealthy => status == 'ok';
}
