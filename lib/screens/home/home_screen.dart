import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/app_colors.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.glaucous,
        foregroundColor: AppColors.vanilla,
        title: const Text('Rick & Morty Explorer'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: AppColors.vanilla);
            }

            final name = snapshot.data!.getString('user_name') ?? 'Explorer';

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.vanilla,
                  size: 85,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome,',
                  style: TextStyle(color: AppColors.powderBlue, fontSize: 18),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.vanilla,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your multiverse adventure starts here!',
                  style: TextStyle(color: AppColors.powderBlue, fontSize: 13),
                ),
                const SizedBox(height: 35),
                ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.glaucous,
                    foregroundColor: AppColors.vanilla,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
