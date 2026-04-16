import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_button.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => _UploadProductScreenState();
}

class _UploadProductScreenState extends State<UploadProductScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String? _selectedCategory;
  File? _imageFile;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Electronics', 'icon': Icons.devices_outlined},
    {'label': 'Books', 'icon': Icons.menu_book_outlined},
    {'label': 'Clothes', 'icon': Icons.checkroom_outlined},
    {'label': 'Furniture', 'icon': Icons.chair_outlined},
    {'label': 'Sports & Fitness', 'icon': Icons.fitness_center_outlined},
    {'label': 'Daily Essentials', 'icon': Icons.local_grocery_store_outlined},
    {'label': 'Leisure & Hobbies', 'icon': Icons.toys_outlined},
    {'label': 'Others', 'icon': Icons.category_outlined},
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String> _uploadImage(File file) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child('products/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descController.text.isEmpty ||
        _selectedCategory == null ||
        _imageFile == null) {
      _showSnack('Please fill in all fields and select an image');
      return;
    }
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showSnack('Please enter a valid price');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final university = await _authService.getUserUniversity();
      final sellerName = await _authService.getUserName();
      final imageUrl = await _uploadImage(_imageFile!);
      await _firestoreService.addProduct(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: price,
        category: _selectedCategory!,
        university: university,
        imageUrl: imageUrl,
        
      );
      if (!mounted) return;
      _showSnack('Product uploaded successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Upload failed: $e');
    }
    setState(() => _isLoading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.darkNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        toolbarHeight: 75, 
        title: const Padding(
          padding: EdgeInsets.only(top: 16.0), 
          child: Text(
            'Upload Product',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        leading: const Padding(
          padding: EdgeInsets.only(top: 16.0), 
          child: BackButton(color: AppColors.campuDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imageFile != null
                        ? AppColors.blue
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.blue, size: 26),
                          ),
                          const SizedBox(height: 10),
                          const Text('Tap to add photo',
                              style: TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('JPG, PNG up to 1MB',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Product name
            _label('Product Name'),
            const SizedBox(height: 8),
            _textField(_titleController, 'e.g. Calculus Textbook 8th Edition'),
            const SizedBox(height: 18),

            // Price
            _label('Price'),
            const SizedBox(height: 8),
            _textField(
              _priceController,
              'e.g. 25.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: const Text(
                'RM ',
                style: TextStyle(
                  color: AppColors.campuDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Description
            _label('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              decoration: _inputDeco(
                'Describe condition, brand, year, any defects...',
              ),
            ),
            const SizedBox(height: 18),

            // Category chips
            _label('Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat['label']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.blue
                          : AppColors.inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? AppColors.blue : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData,
                            size: 16,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // University info box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.blue.withOpacity(0.2), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.school_outlined,
                      size: 16, color: AppColors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'University is auto-filled from your profile',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            AppButton(
              label: 'Upload Product',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 15, 
        fontWeight: FontWeight.w800, 
        color: AppColors.campuDark,
        letterSpacing: 0.6, 
      ),
    );

  Widget _textField(
    TextEditingController c,
    String hint, {
    TextInputType? keyboardType,
    Widget? prefix,
  }) =>
      TextField(
        controller: c,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: _inputDeco(hint).copyWith(prefix: prefix),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.blue, width: 1.5)),
      );
}