import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'edit_product_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  int selectedTab = 0; // 0=posted,1=fav,2=sold
  final user = FirebaseAuth.instance.currentUser;
  final service = FirestoreService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await AuthService().logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<String>(
                    future: AuthService().getUserName(),
                    builder: (context, snapshot) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Welcome",
                              style: TextStyle(color: Colors.white70)),
                          Text(
                            snapshot.data ?? "",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== NEW CARD BUTTONS =====
            Row(
              children: [
                _buildMenuCard("Posted Products", Icons.inventory, 0),
                _buildMenuCard("Favourite", Icons.favorite, 1),
                _buildMenuCard("Sold", Icons.check_circle, 2),
              ],
            ),

            const SizedBox(height: 20),

            // ===== CONTENT SWITCH =====
            Expanded(
              child: selectedTab == 0
                  ? _buildListings()
                  : selectedTab == 1
                      ? _buildFavourites()
                      : _buildSold(),
            ),
          ],
        ),
      ),
    );
  }

  // ===== MENU CARD =====
  Widget _buildMenuCard(String title, IconData icon, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== POSTED =====
  Widget _buildListings() {
  return StreamBuilder(
    stream: FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: user?.uid)
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final listings = snapshot.data!.docs;

      if (listings.isEmpty) {
        return const Center(child: Text("No posted products"));
      }

      return ListView.builder(
        itemCount: listings.length,
        itemBuilder: (context, index) {

          final data = listings[index].data() as Map<String, dynamic>;
          final docId = listings[index].id;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(

              // IMAGE
              leading: SizedBox(
                width: 50,
                height: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image),
                  ),
                ),
              ),

              // TITLE + PRICE
              title: Text(data['title']),
              subtitle: Text("RM ${data['price']}"),

              // ACTION BUTTONS
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // EDIT
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(
                            docId: docId,
                            data: data,
                          ),
                        ),
                      );
                    },
                  ),

                  // DELETE WITH CONFIRMATION
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Delete Item"),
                            content: const Text(
                                "Are you sure you want to delete this product?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('products')
                            .doc(docId)
                            .delete();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Product deleted"),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

}

  // ===== FAVOURITE =====
  Widget _buildFavourites() {
  return StreamBuilder(
    stream: service.getFavourites(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final favs = snapshot.data!.docs;

      if (favs.isEmpty) {
        return const Center(child: Text("No favourites"));
      }

      return ListView.builder(
        itemCount: favs.length,
        itemBuilder: (context, index) {

          final productId = favs[index]['productId'];

          return FutureBuilder(
            future: service.getProductById(productId),
            builder: (context, snap) {

              if (!snap.hasData) return const SizedBox();

              final data = snap.data!.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(

                  // IMAGE
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image),
                      ),
                    ),
                  ),

                  // TITLE + PRICE
                  title: Text(data['title']),
                  subtitle: Text("RM ${data['price']}"),

                  // ❤️ REMOVE BUTTON
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {

                      await service.removeFavourite(productId);

                      if (mounted) {
                        setState(() {});
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Removed from favourites"),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

  // ===== SOLD (TEMP PLACEHOLDER) =====
  Widget _buildSold() {
    return const Center(
      child: Text("No sold products yet"),
    );
  }
}