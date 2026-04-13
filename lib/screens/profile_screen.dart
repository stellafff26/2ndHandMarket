import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import '../widgets/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.w700, 
              color: AppColors.textPrimary, 
            ),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, 
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1), 
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: IconButton(
              icon: const Icon(Icons.bar_chart_outlined),
              tooltip: 'Dashboard',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: IconButton(
              icon: const Icon(Icons.logout_outlined),
              tooltip: 'Logout',
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Profile',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}