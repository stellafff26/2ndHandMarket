import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../widgets/app_colors.dart';
import 'order_chat_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getUserChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.blue));
          
          final chats = snapshot.data!.docs;
          if (chats.isEmpty) {
            return const Center(
              child: Text('No messages yet.', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;
              final productId = chatData['productId'];

              return FutureBuilder<DocumentSnapshot>(
                future: service.getProductById(productId),
                builder: (context, productSnap) {
                  if (!productSnap.hasData || !productSnap.data!.exists) return const SizedBox();
                  
                  final productData = productSnap.data!.data() as Map<String, dynamic>;

                  final isSeller = productData['sellerId'] == service.uid;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    tileColor: Colors.white,
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.inputBg,
                          backgroundImage: productData['imageUrl'] != null ? NetworkImage(productData['imageUrl']) : null,
                          child: productData['imageUrl'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: isSeller ? AppColors.orange : AppColors.blue,
                            child: Icon(isSeller ? Icons.storefront : Icons.shopping_bag, size: 12, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                    title: Text(
                      productData['title'] ?? 'Item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      chatData['lastMessage'] ?? '...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderChatScreen(
                            chatId: chatId,
                            productData: productData,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}