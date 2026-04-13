import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/product_model.dart';
import '../widgets/app_colors.dart';
import 'upload_product_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),   
    const SizedBox(),      
    const ProfileScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1.0), 
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0, 
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.blue, 
          unselectedItemColor: AppColors.campuDark, 
          type: BottomNavigationBarType.fixed, 
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
          onTap: (index) {
            if (index == 1) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UploadProductScreen()));
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        toolbarHeight: 75,
        title: const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(
                  text: 'Campu',
                  style: TextStyle(color: AppColors.orange),
                ),
                TextSpan(
                  text: 'Swap',
                  style: TextStyle(color: AppColors.blue),
                ),
              ],
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
      ),
      body: const Center(
        child: Text(
          'Homepage',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}