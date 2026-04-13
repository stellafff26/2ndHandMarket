import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // Products 
  Future<void> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String university,
    required String imageUrl,
    required String sellerName,
  }) async {
    await _db.collection('products').add({
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'university': university,
      'imageUrl': imageUrl,
      'sellerId': uid,
      'sellerName': sellerName,
      'createdAt': Timestamp.now(),
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

  Future<DocumentSnapshot> getProductById(String docId) async {
    return await _db.collection('products').doc(docId).get();
  }

  Future<void> deleteProduct(String docId) async {
    await _db.collection('products').doc(docId).delete();
  }

  Future<void> updateProduct(String docId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(docId).update(data);
  }

  // Favourites 
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

  // Dashboard 
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
}
