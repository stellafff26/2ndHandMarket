import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/app_colors.dart';
import '../models/product_model.dart';
import 'upload_product_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  final FirestoreService _service = FirestoreService();

  final List<Widget> pages = [
    const HomeContent(),
    const SizedBox(), 
    const ProfileScreen(),
    const NotificationScreen(), 
  ];

  Widget _buildInboxIcon(bool isActive) {
    return StreamBuilder<int>(
      stream: _service.getUnreadChatCount(), 
      builder: (context, snapshot) {
        final int unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(isActive ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.campuDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
  
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box_rounded),
            label: 'Upload',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: _buildInboxIcon(false),
            activeIcon: _buildInboxIcon(true),
            label: 'Inbox', 
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UploadProductScreen(),
              ),
            );
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  final FirestoreService service = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(dynamic product) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return product.title.toLowerCase().contains(q) ||
        product.category.toLowerCase().contains(q) ||
        product.university.toLowerCase().contains(q);
  }

  bool _matchesCategory(dynamic product) {
    if (_selectedCategory == 'All') return true;
    return product.category == _selectedCategory;
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('book')) return Icons.menu_book_rounded;
    if (c.contains('electronic')) return Icons.devices_other_rounded;
    if (c.contains('cloth') || c.contains('fashion')) return Icons.checkroom_rounded;
    if (c.contains('furniture')) return Icons.chair_alt_rounded;
    if (c.contains('sport')) return Icons.sports_basketball_rounded;
    if (c.contains('beauty')) return Icons.face_retouching_natural_rounded;
    if (c.contains('food')) return Icons.fastfood_rounded;
    if (c.contains('toy') || c.contains('game') || c.contains('hobbies')) return Icons.extension_rounded;
    return Icons.category_rounded;
  }

  Color _categoryColor(String category) {
    final c = category.toLowerCase();
    if (c.contains('book')) return Colors.deepPurple;
    if (c.contains('electronic')) return AppColors.blue;
    if (c.contains('cloth') || c.contains('fashion')) return Colors.pink;
    if (c.contains('furniture')) return Colors.brown;
    if (c.contains('sport')) return Colors.green;
    if (c.contains('beauty')) return Colors.purple;
    if (c.contains('food')) return Colors.redAccent;
    if (c.contains('toy') || c.contains('game') || c.contains('hobbies')) return AppColors.orange;
    return AppColors.campuDark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: service.getAllProducts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final allProducts = docs
                .where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] != 'sold'; 
                })
                .map((doc) => ProductModel.fromDoc(doc))
                .toList();
            
            final categories = <String>{
              'All',
              ...allProducts.map((p) => p.category).where((c) => c.isNotEmpty)
            }.toList();
            
            final featuredCategories = categories.where((c) => c != 'All').take(8).toList();
            final filteredProducts = allProducts.where((product) {
              return _matchesSearch(product) && _matchesCategory(product);
            }).toList();

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 26,
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
                      const SizedBox(height: 8),
                      const Text(
                        'Discover second-hand deals on campus',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by title, category, or univ',
                            hintStyle: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : const Icon(
                                    Icons.tune_rounded,
                                    color: AppColors.campuDark,
                                    size: 18,
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (featuredCategories.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Featured Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = featuredCategories[index];
                        final isSelected = _selectedCategory == category;
                        final color = _categoryColor(category);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 96,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withOpacity(0.12) : AppColors.inputBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 1.4,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected ? color.withOpacity(0.16) : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _categoryIcon(category),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      category,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? color : AppColors.campuDark,
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.blue : AppColors.inputBg,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category == 'All' ? Icons.apps_rounded : Icons.category_outlined,
                                size: 15,
                                color: isSelected ? Colors.white : AppColors.campuDark,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.campuDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: allProducts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 42,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'No products yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Be the first to upload an item and start your campus marketplace.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredProducts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: AppColors.inputBg,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(
                                        Icons.search_off_rounded,
                                        size: 42,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'No matching products',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No result found for "${_searchQuery.trim()}". Try another keyword.'
                                          : 'No products available in this category.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final productId = product.id;
                                final currentUserId = service.uid;
                                final sellerId = product.sellerId;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProductDetailScreen(product: product),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: SizedBox(
                                              width: 88,
                                              height: 88,
                                              child: product.imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      product.imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: AppColors.inputBg,
                                                          child: const Icon(
                                                            Icons.broken_image_outlined,
                                                            color: AppColors.textSecondary,
                                                            size: 30,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Container(
                                                      color: AppColors.inputBg,
                                                      child: const Icon(
                                                        Icons.image_outlined,
                                                        color: AppColors.textSecondary,
                                                        size: 30,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'RM ${product.price.toStringAsFixed(1)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.blue,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    _HomeChip(
                                                      icon: Icons.category_outlined,
                                                      label: product.category,
                                                      backgroundColor: AppColors.orange.withOpacity(0.10),
                                                      textColor: AppColors.orange,
                                                    ),
                                                    _HomeChip(
                                                      icon: Icons.school_outlined,
                                                      label: product.university,
                                                      backgroundColor: AppColors.blue.withOpacity(0.08),
                                                      textColor: AppColors.blue,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            children: [
                                              if (currentUserId == sellerId)
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.inputBg,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: IconButton(
                                                    icon: const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                                                    onPressed: () {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('You cannot favourite your own product')),
                                                      );
                                                    },
                                                  ),
                                                )
                                              else
                                                StreamBuilder<QuerySnapshot>(
                                                  stream: FirebaseFirestore.instance
                                                      .collection('favourites')
                                                      .doc(currentUserId)
                                                      .collection('items')
                                                      .snapshots(),
                                                  builder: (context, favSnapshot) {
                                                    if (!favSnapshot.hasData) {
                                                      return Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: AppColors.inputBg,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      );
                                                    }
                                                    
                                                    final favDocs = favSnapshot.data!.docs;
                                                    final isFav = favDocs.any((doc) => doc['productId'] == productId);

                                                    return Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: isFav ? Colors.red.withOpacity(0.08) : AppColors.inputBg,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                          isFav ? Icons.favorite : Icons.favorite_border,
                                                          color: isFav ? Colors.red : Colors.grey,
                                                          size: 20,
                                                        ),
                                                        onPressed: () async {
                                                          if (isFav) {
                                                            await service.removeFavourite(productId);
                                                          } else {
                                                            await service.addFavourite(productId);
                                                          }
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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

class _HomeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _HomeChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
