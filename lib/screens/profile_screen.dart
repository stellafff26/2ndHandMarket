import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_colors.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';
import 'order_chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  int selectedTab = 0; // 0: posted, 1: fav, 2: sold
  final service = FirestoreService();
  final auth = AuthService();
  
  User? get currentUser => FirebaseAuth.instance.currentUser;
  
  String _name = '';
  String _email = '';
  String _university = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingUser = false;
        });
        return;
      }
      
      final data = await auth.getUserData();
      if (!mounted) return;
      
      setState(() {
        _name = data?['username'] ?? '';
        _email = data?['email'] ?? currentUser?.email ?? '';
        _university = data?['university'] ?? '';
        _isLoadingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUser = false;
      });
      _showSnack('Failed to load profile data');
    }
  }

  String get _initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await auth.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F8FB),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: AppColors.campuDark),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: AppColors.border, height: 1),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: AppColors.inputBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    size: 34,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'You are not logged in',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please log in to view your profile, listings, and favourites.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: AppColors.campuDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Insights',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // USER INFO HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name.isNotEmpty ? _name : 'User',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_university.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_outlined,
                                  size: 12,
                                  color: AppColors.blue,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _university,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w600,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TAB CARDS
            const SizedBox(height: 16),
            Row(
              children: [
                buildMenuCard('Posted', Icons.inventory_2_outlined, 0),
                buildMenuCard('Saves', Icons.favorite_border, 1), 
                buildMenuCard('Bought', Icons.shopping_bag_outlined, 2), 
                buildMenuCard('Sold', Icons.check_circle_outline, 3),
              ],
            ),
            const SizedBox(height: 16),
            // TAB CONTENT
            Expanded(
              child: IndexedStack(
                index: selectedTab,
                children: [
                  _buildListings(),   // 0
                  _buildFavourites(), // 1
                  _buildBought(),     // 2
                  _buildSold(),       // 3
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuCard(String title, IconData icon, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3), 
          padding: const EdgeInsets.symmetric(vertical: 12), 
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orange : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.orange : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20, 
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.inputBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard({
    required String imageUrl,
    required String title,
    required dynamic price,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: AppColors.inputBg,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: AppColors.textSecondary,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (subtitle != null) 
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  'RM $price',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildBought() {
    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('bought_stream'),
      stream: service.getBoughtProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorState(snapshot.error.toString());
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final items = snapshot.data!.docs;
        if (items.isEmpty) return _emptyState('You haven\'t bought anything yet', Icons.shopping_bag_outlined);

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final data = items[index].data() as Map<String, dynamic>;
            final productId = items[index].id; 
            
            return GestureDetector(
              onTap: () async {
                final chatId = await service.getOrCreateChat(
                  buyerId: service.uid, 
                  sellerId: data['sellerId'], 
                  productId: productId,
                );
                if (!context.mounted) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => OrderChatScreen(
                  chatId: chatId, productData: data,
                )));
              },
              child: _productCard(
                imageUrl: data['imageUrl'] ?? '',
                title: data['title'] ?? '',
                price: data['price'] ?? 0,
                trailing: const Icon(Icons.verified_outlined, color: Colors.blue, size: 20),
              ),
            );
          },
        );
      },
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Text('Error loading data. Check index.', style: TextStyle(color: Colors.red[300], fontSize: 12)),
    );
  }

  Widget _buildListings() {
    if (currentUser == null) {
      return _emptyState('Please log in to view your products', Icons.lock_outline);
    }

    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('posted_stream'),
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }

        final listings = snapshot.data!.docs;
        if (listings.isEmpty) {
          return _emptyState('No posted products yet', Icons.inventory_2_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final data = listings[index].data() as Map<String, dynamic>;
            final docId = listings[index].id;

            return _productCard(
              imageUrl: data['imageUrl'] ?? '',
              title: data['title'] ?? '',
              price: data['price'] ?? 0,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.blue,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProductScreen(
                            docId: docId,
                            data: data,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              'Delete Product',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this product?',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                        if (mounted) _showSnack('Product deleted');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavourites() {
    if (currentUser == null) {
      return _emptyState('Please log in to view favourites', Icons.lock_outline);
    }

    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('favourites_stream'),
      stream: service.getFavourites(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }

        final favItems = snapshot.data?.docs ?? [];
        if (favItems.isEmpty) {
          return _emptyState('No favourites yet', Icons.favorite_border);
        }
        final favs = snapshot.data!.docs;
        if (favs.isEmpty) {
          return _emptyState('No favourites yet', Icons.favorite_border);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: favs.length,
          itemBuilder: (context, index) {
            final favData = favItems[index].data() as Map<String, dynamic>;
            final productId = favData['productId'];

            return FutureBuilder<DocumentSnapshot>(
              future: service.getProductById(productId),
              builder: (context, productSnap) {
                if (!productSnap.hasData || !productSnap.data!.exists) return const SizedBox();
                final product = ProductModel.fromDoc(productSnap.data!);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
                    );
                  },
                  child: _productCard(
                    imageUrl: product.imageUrl,
                    title: product.title,
                    price: product.price,
                    trailing: const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSold() {
    if (currentUser == null) {
      return _emptyState('Please log in to view sold products', Icons.lock_outline);
    }

    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('sold_stream'),
      stream: service.getSoldProducts(), 
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Load Fail, please check if Firestore indexes need to be created in Android Studio console.\n\nDetailed error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }

        final soldListings = snapshot.data?.docs ?? [];

        if (soldListings.isEmpty) {
          return _emptyState('No sold products yet', Icons.check_circle_outline);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: soldListings.length,
          itemBuilder: (context, index) {
            final data = soldListings[index].data() as Map<String, dynamic>;
            final docId = soldListings[index].id;

            return GestureDetector(
              onTap: () async {
                final chatId = await service.getOrCreateChat(
                  buyerId: data['buyerId'] ?? '', 
                  sellerId: service.uid,          
                  productId: docId,              
                );
                
                if (!context.mounted) return;
                
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => OrderChatScreen(
                      chatId: chatId, 
                      productData: data,
                    ),
                  ),
                );
              },
              child: _productCard(
                imageUrl: data['imageUrl'] ?? '',
                title: data['title'] ?? '',
                price: data['price'] ?? 0,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Sold',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
