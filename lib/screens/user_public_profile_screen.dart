import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_colors.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';

class UserPublicProfileScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserPublicProfileScreen({
    super.key, 
    required this.userId, 
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("$userName's Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.inputBg,
                    child: Icon(Icons.person, size: 40, color: AppColors.campuDark),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                    builder: (context, snapshot) {
                      String university = "University Student"; 
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        university = data['university'] ?? "University Student";
                      }
                      return Text(
                        university,
                        style: const TextStyle(color: AppColors.textSecondary),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Active Listings", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('sellerId', isEqualTo: userId) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("Data error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  );
                }
                
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final products = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] != 'sold';
                }).toList();
                
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No active items for sale."),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = ProductModel.fromDoc(products[index]);
                    
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: product),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover, 
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.title, 
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis, 
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "RM ${product.price.toStringAsFixed(1)}", 
                                    style: const TextStyle(
                                      color: AppColors.blue, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}