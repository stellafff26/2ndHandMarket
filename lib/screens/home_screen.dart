import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.campuDark,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadProductScreen()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

// ================= HOME CONTENT =================

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {

  final FirestoreService service = FirestoreService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        toolbarHeight: 75,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              children: const [
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),

      body: StreamBuilder(
        stream: service.getAllProducts(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("No products yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {

              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;
              final productId = doc.id;

              final currentUserId = service.uid;
              final sellerId = data['sellerId'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(

                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  leading: SizedBox(
                    width: 60,
                    height: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: data['imageUrl'] != null
                          ? Image.network(data['imageUrl'], fit: BoxFit.cover)
                          : const Icon(Icons.image),
                    ),
                  ),

                  title: Text(
                    data['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text("RM ${data['price']}"),

                  // ✅ FIXED TRAILING (ALIGNED + LOGIC)
                  trailing: SizedBox(
                    width: 40,
                    child: Center(
                      child: currentUserId == sellerId
                          // 🚫 OWN PRODUCT BLOCK
                          ? IconButton(
                              icon: const Icon(Icons.favorite_border, color: Colors.grey),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("You cannot favourite your own product"),
                                  ),
                                );
                              },
                            )

                          // ❤️ REAL-TIME FAV
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('favourites')
                                  .doc(currentUserId)
                                  .collection('items')
                                  .snapshots(),
                              builder: (context, favSnapshot) {

                                if (!favSnapshot.hasData) {
                                  return const SizedBox();
                                }

                                final favDocs = favSnapshot.data!.docs;

                                final isFav = favDocs.any(
                                  (doc) => doc['productId'] == productId,
                                );

                                return IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite : Icons.favorite_border,
                                    color: isFav ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    if (isFav) {
                                      await service.removeFavourite(productId);
                                    } else {
                                      await service.addFavourite(productId);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}