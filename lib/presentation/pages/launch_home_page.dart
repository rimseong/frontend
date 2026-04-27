import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:launch_frontend/bloc/dashboard/launch_dashboard_bloc.dart';
import 'package:launch_frontend/bloc/dashboard/launch_dashboard_event.dart';
import 'package:launch_frontend/bloc/dashboard/launch_dashboard_state.dart';
import 'package:launch_frontend/domain/entities/restaurant.dart';
import 'package:launch_frontend/domain/entities/user.dart';
import 'package:launch_frontend/presentation/pages/login_page.dart';

class LaunchHomePage extends StatefulWidget {
  const LaunchHomePage({Key? key}) : super(key: key);

  @override
  State<LaunchHomePage> createState() => _LaunchHomePageState();
}

class _LaunchHomePageState extends State<LaunchHomePage> {
  String get _todayTitle {
    final now = DateTime.now();
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    return '${now.month}월 ${now.day}일 ${weekdays[now.weekday - 1]}';
  }

  @override
  void initState() {
    super.initState();
    context.read<LaunchDashboardBloc>().add(const LaunchDashboardStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LaunchDashboardBloc, LaunchDashboardState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_todayTitle),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                tooltip: 'Login',
                icon: const Icon(Icons.login),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<LaunchDashboardBloc>().add(const LaunchDashboardRefreshed());
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _HealthCard(state: state),
                const SizedBox(height: 24),
                _UserSection(users: state.users),
                const SizedBox(height: 24),
                _RestaurantSection(restaurants: state.restaurants),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(state.errorMessage!),
                    ),
                  ),
                ],
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              context.read<LaunchDashboardBloc>().add(const LaunchDashboardRefreshed());
            },
            tooltip: 'Refresh',
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        );
      },
    );
  }
}

class _HealthCard extends StatelessWidget {
  final LaunchDashboardState state;

  const _HealthCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.users.isEmpty && state.restaurants.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final isHealthy = state.healthStatus.isHealthy;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHealthy ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isHealthy ? 'Backend is running' : 'Backend error',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final List<User> users;

  const _UserSection({required this.users});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Direct Employees (${users.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (users.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No employees found'),
            ),
          )
        else
          ...users.map(
            (user) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(user.name.isEmpty ? 'Unknown' : user.name),
                subtitle: Text('Employee #: ${user.employeeNo} | Role: ${user.role}'),
                trailing: Chip(
                  label: Text(user.role),
                  backgroundColor: user.role == 'admin' ? Colors.orange[200] : Colors.blue[200],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RestaurantSection extends StatelessWidget {
  final List<Restaurant> restaurants;

  const _RestaurantSection({required this.restaurants});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restaurants (${restaurants.length})',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (restaurants.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No restaurants found'),
            ),
          )
        else
          ...restaurants.map(
            (restaurant) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(restaurant.name.isEmpty ? 'Unknown' : restaurant.name),
                trailing: Chip(
                  label: Text(restaurant.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: restaurant.isActive ? Colors.green[200] : Colors.grey[200],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
