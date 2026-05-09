import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditProductScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<EditProductScreen> createState() => EditProductScreenState();
}

class EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController descController;
  
  String? selectedCategory;
  
  final List<Map<String, dynamic>> categories = [
    {'label': 'Electronics', 'icon': Icons.devices_outlined},
    {'label': 'Books', 'icon': Icons.menu_book_outlined},
    {'label': 'Clothes', 'icon': Icons.checkroom_outlined},
    {'label': 'Furniture', 'icon': Icons.chair_outlined},
    {'label': 'Sports & Fitness', 'icon': Icons.fitness_center_outlined},
    {'label': 'Daily Essentials', 'icon': Icons.local_grocery_store_outlined},
    {'label': 'Leisure & Hobbies', 'icon': Icons.toys_outlined},
    {'label': 'Others', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.data['title']);
    priceController = TextEditingController(text: widget.data['price'].toString());
    descController = TextEditingController(text: widget.data['description']);
    selectedCategory = widget.data['category'];
  }

  Future<void> updateProduct() async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.docId)
        .update({
      'title': titleController.text,
      'price': double.parse(priceController.text),
      'description': descController.text,
      'category': selectedCategory,
    });
    
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated successfully")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: "Price"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: "Description",
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Category",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = cat['label'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProduct,
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}