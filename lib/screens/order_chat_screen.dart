import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/firestore_service.dart';
import '../widgets/app_colors.dart';
import 'user_public_profile_screen.dart';
import 'product_detail_screen.dart'; 
import '../models/product_model.dart'; 

class OrderChatScreen extends StatefulWidget {
  final String chatId;
  final Map<String, dynamic> productData;

  const OrderChatScreen({
    super.key,
    required this.chatId,
    required this.productData,
  });

  @override
  State<OrderChatScreen> createState() => OrderChatScreenState();
}

class OrderChatScreenState extends State<OrderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _service = FirestoreService();
  bool _isGeneratingAi = false;
  late Future<Map<String, String>> _partnerInfoFuture;

  @override
  void initState() {
    super.initState();
    _partnerInfoFuture = _fetchPartnerInfo();
    
    _service.markChatAsRead(widget.chatId);
  }

  Future<Map<String, String>> _fetchPartnerInfo() async {
    String pId = "";
    
    if (_service.uid == widget.productData['sellerId']) {
      if (widget.productData['buyerId'] != null) {
        pId = widget.productData['buyerId'];
      } else {
        try {
          final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
          if (chatDoc.exists) {
            final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
            pId = participants.firstWhere((id) => id != _service.uid, orElse: () => widget.chatId.split('_')[0]);
          } else {
            pId = widget.chatId.split('_')[0]; 
          }
        } catch (e) {
          pId = widget.chatId.split('_')[0];
        }
      }
    } else {
      pId = widget.productData['sellerId'] ?? '';
    }

    String pName = (_service.uid == widget.productData['sellerId']) ? 'Buyer' : (widget.productData['sellerName'] ?? 'Seller');
    
    if (pId.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(pId).get();
        if (userDoc.exists) {
          pName = userDoc.data()?['username'] ?? pName;
        }
      } catch (e) {
        // ignore errors, use default name
      }
    }

    return {'id': pId, 'name': pName};
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '...';
    final date = timestamp.toDate();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(date.hour)}:${pad(date.minute)}';
  }

  String _getDateDividerText(Timestamp? timestamp) {
    if (timestamp == null) return 'Today';

    final date = timestamp.toDate();
    final now = DateTime.now();

    final dateOnly = DateTime(date.year, date.month, date.day);
    final nowOnly = DateTime(now.year, now.month, now.day);
    final diffDays = nowOnly.difference(dateOnly).inDays;

    if (diffDays == 0) {
      return 'Today';
    } else if (diffDays == 1) {
      return 'Yesterday';
    } else if (diffDays > 1 && diffDays < 7) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _generateAiReply(List<QueryDocumentSnapshot> recentMessages) async {
    setState(() => _isGeneratingAi = true);
    try {
      String history = recentMessages.take(6).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isMe = data['senderId'] == _service.uid;
        return "${isMe ? 'Me' : 'Them'}: ${data['text']}";
      }).toList().reversed.join('\n');

      final productStatus = widget.productData['status'] == 'sold' ? 'SOLD OUT' : 'AVAILABLE';
      final productTitle = widget.productData['title'] ?? 'Item';
      final productPrice = widget.productData['price']?.toString() ?? 'Unknown';
      
      final isMeSeller = _service.uid == widget.productData['sellerId'];
      final myRole = isMeSeller ? 'Seller' : 'Buyer';
      final partnerRole = isMeSeller ? 'Buyer' : 'Seller';

      const apiKey = 'Gemini API Key'; // API Key
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      
      final prompt = """
      You are an intelligent chat assistant in a campus second-hand marketplace app specifically for Universiti Malaya students.
      You are generating a reply on behalf of "me".
      
      Context:
      - My Role: $myRole
      - Partner's Role: $partnerRole
      - Product: $productTitle
      - Price: RM $productPrice
      - Current Status: $productStatus

      Response Guidelines:
      1. If the Current Status is "SOLD OUT": This means the transaction is confirmed between me and this specific $partnerRole. DO NOT say the item is unavailable. Instead, focus entirely on arranging the meetup/handover. Suggest specific Universiti Malaya landmarks (e.g., KK, library, faculty buildings, or LRT station) and a suitable time.
         - If I am the $myRole (Seller): Coordinate how and when to give the item to the buyer.
         - If I am the $myRole (Buyer): Coordinate how and when to collect the item from the seller.
      2. If the Current Status is "AVAILABLE": Help with the negotiation.
         - If I am the $myRole (Seller): Answer questions, persuade the buyer, and suggest a meetup.
         - If I am the $myRole (Buyer): Inquire about the condition, negotiate the price, or ask to meet up.
      3. Tone & Style: Concise, friendly, polite, and natural for a university student. 
         - CRITICAL: NEVER start your sentence with overly enthusiastic AI filler words like "Great", "Awesome", "Perfect", or "Excellent". 
         - If a greeting is appropriate, use a simple "Hi" or "Hey". Otherwise, just get straight to the point.
      
      CRITICAL: Output the reply directly. Do not include any conversational filler, explanations, markdown formatting, or surrounding quotation marks.

      Chat history:
      $history
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        _messageController.text = response.text!.trim();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI generation failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.campuDark),
        title: FutureBuilder<Map<String, String>>(
          future: _partnerInfoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Loading...", style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18));
            }
            
            final pId = snapshot.data?['id'] ?? '';
            final pName = snapshot.data?['name'] ?? 'User';

            return GestureDetector(
              onTap: () {
                if (pId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserPublicProfileScreen(
                        userId: pId,
                        userName: pName,
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  Text(
                    pName,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () async {
              try {
                final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
                final productId = chatDoc.data()?['productId'] ?? widget.productData['id'];
                
                if (productId != null) {
                  final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
                  
                  if (productDoc.exists && mounted) {
                    final product = ProductModel.fromDoc(productDoc);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Error navigating to product detail: $e");
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.productData['imageUrl'] != null &&
                           widget.productData['imageUrl'].toString().isNotEmpty
                        ? Image.network(
                            widget.productData['imageUrl'],
                            width: 50, height: 50, fit: BoxFit.cover,
                          )
                        : Container(
                            width: 50, height: 50, color: AppColors.inputBg, 
                            child: const Icon(Icons.image),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productData['title'] ?? 'Unknown Product',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM ${widget.productData['price']}',
                          style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.productData['status'] == 'sold' 
                          ? Colors.green.withOpacity(0.1) 
                          : AppColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.productData['status'] == 'sold' ? 'SOLD' : 'AVAILABLE',
                      style: TextStyle(
                        color: widget.productData['status'] == 'sold' 
                            ? Colors.green : AppColors.orange,
                        fontWeight: FontWeight.bold, fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.blue));
                
                final docs = snapshot.data!.docs;
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        reverse: true, 
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final isMe = data['senderId'] == _service.uid;
                          final timestamp = data['timestamp'] as Timestamp?;
                          
                          bool showDateDivider = false;
                          if (index == docs.length - 1) {
                            showDateDivider = true;
                          } else {
                            final olderData = docs[index + 1].data() as Map<String, dynamic>;
                            final olderTimestamp = olderData['timestamp'] as Timestamp?;

                            if (timestamp != null && olderTimestamp != null) {
                              final date = timestamp.toDate();
                              final olderDate = olderTimestamp.toDate();
                              if (date.year != olderDate.year || date.month != olderDate.month || date.day != olderDate.day) {
                                showDateDivider = true;
                              }
                            }
                          }
                          
                          return Column(
                            children: [
                              if (showDateDivider)
                                Container(
                                  margin: const EdgeInsets.symmetric(vertical: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    _getDateDividerText(timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),

                              Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.blue : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(15).copyWith(
                                      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                                      bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        data['text'] ?? '',
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTime(timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    _buildInputArea(docs),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(List<QueryDocumentSnapshot> recentMessages) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: _isGeneratingAi
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Color(0xFF8C52FF)),
            onPressed: _isGeneratingAi ? null : () => _generateAiReply(recentMessages),
            tooltip: 'Smart Reply',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true, fillColor: AppColors.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () {
                if (_messageController.text.trim().isNotEmpty) {
                  _service.sendMessage(widget.chatId, _messageController.text);
                  _messageController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
