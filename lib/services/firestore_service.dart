import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // --- Products ---
  Future<void> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String university,
    required String imageUrl,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;
    final sellerName = userData['username'] ?? 'Unknown';

    await _db.collection('products').add({
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'university': university,
      'imageUrl': imageUrl,
      'sellerId': uid,
      'sellerName': sellerName,
      'status': 'available', 
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> markProductAsSold(String productId) async {
    await _db.collection('products').doc(productId).update({
      'status': 'sold',
      'buyerId': uid, 
      'soldAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getAllProducts() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMyProducts() {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getSoldProducts() {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: uid)
        .where('status', isEqualTo: 'sold')
        .orderBy('soldAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getBoughtProducts() {
    return _db
        .collection('products')
        .where('buyerId', isEqualTo: uid)
        .where('status', isEqualTo: 'sold')
        .orderBy('soldAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getProductById(String docId) async {
    return await _db.collection('products').doc(docId).get();
  }

  Future<void> deleteProduct(String docId) async {
    await _db.collection('products').doc(docId).delete();
  }

  Future<void> updateProduct(String docId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(docId).update(data);
  }

  // --- Favourites ---
  Future<void> addFavourite(String productId) async {
    await _db
        .collection('favourites')
        .doc(uid)
        .collection('items')
        .doc(productId)
        .set({'productId': productId, 'addedAt': Timestamp.now()});
  }

  Future<void> removeFavourite(String productId) async {
    await _db
        .collection('favourites')
        .doc(uid)
        .collection('items')
        .doc(productId)
        .delete();
  }

  Future<bool> isFavourited(String productId) async {
    final doc = await _db
        .collection('favourites')
        .doc(uid)
        .collection('items')
        .doc(productId)
        .get();
    return doc.exists;
  }

  Stream<QuerySnapshot> getFavourites() {
    return _db
        .collection('favourites')
        .doc(uid)
        .collection('items')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // --- Dashboard ---
  Future<int> getMyProductCount() async {
    final snap = await _db
        .collection('products')
        .where('sellerId', isEqualTo: uid)
        .get();
    return snap.docs.length;
  }

  Future<int> getMyFavouriteCount() async {
    final snap = await _db
        .collection('favourites')
        .doc(uid)
        .collection('items')
        .get();
    return snap.docs.length;
  }

  Future<Map<String, int>> getProductCountByCategory() async {
    final snap = await _db.collection('products').get();
    final Map<String, int> counts = {};
    for (var doc in snap.docs) {
      final cat = doc['category'] as String? ?? 'Others';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  Future<double> getMyAveragePrice() async {
    final snap = await _db
        .collection('products')
        .where('sellerId', isEqualTo: uid)
        .get();
    if (snap.docs.isEmpty) return 0;
    final total = snap.docs
        .map((d) => (d['price'] as num).toDouble())
        .reduce((a, b) => a + b);
    return total / snap.docs.length;
  }

  // --- Chats & Messages ---
  Future<String> getOrCreateChat({
    required String buyerId,
    required String sellerId,
    required String productId,
  }) async {
    final String chatId = "${buyerId}_${sellerId}_$productId";
    final chatDoc = await _db.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      final buyerData = await _db.collection('users').doc(buyerId).get();
      final sellerData = await _db.collection('users').doc(sellerId).get();
      
      await _db.collection('chats').doc(chatId).set({
        'participants': [buyerId, sellerId],
        'buyerName': buyerData.data()?['username'] ?? 'User', 
        'sellerName': sellerData.data()?['username'] ?? 'User', 
        'productId': productId,
        'unreadBy': [], // 初始化未读状态为空
      });
    }
    return chatId;
  }

  Future<void> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return;

    final messageData = {
      'senderId': uid,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Save message
    await _db.collection('chats').doc(chatId).collection('messages').add(messageData);

    // 获取对方的 ID
    String receiverId = '';
    try {
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
        receiverId = participants.firstWhere((id) => id != uid, orElse: () => '');
      }
    } catch (e) {
      // 忽略错误
    }

    // Update last message in chat doc AND unreadBy array
    await _db.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastTimestamp': FieldValue.serverTimestamp(),
      // 标记对方未读：使用 arrayUnion 避免重复添加
      'unreadBy': receiverId.isNotEmpty ? FieldValue.arrayUnion([receiverId]) : [], 
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }

  // --- Read Receipts (Sync Inbox & Bottom NavBar) ---

  // 1. 获取未读聊天的数量 (用于主页的红点)
  Stream<int> getUnreadChatCount() {
    return _db
        .collection('chats')
        .where('unreadBy', arrayContains: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // 2. 将特定聊天标记为已读 (从 unreadBy 中移除当前用户)
  Future<void> markChatAsRead(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'unreadBy': FieldValue.arrayRemove([uid]),
    });
  }
}