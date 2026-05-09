import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; 

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_button.dart';

class UploadProductScreen extends StatefulWidget {
  const UploadProductScreen({super.key});

  @override
  State<UploadProductScreen> createState() => UploadProductScreenState();
}

class UploadProductScreenState extends State<UploadProductScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  String? _selectedCategory;
  File? _imageFile;
  bool _isLoading = false;
  bool _isAiLoading = false; 

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
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _generateDescriptionWithAi() async {
    if (_imageFile == null) {
      _showSnack('Please upload an image first to use AI assistant.');
      return;
    }

    setState(() => _isAiLoading = true);

    try {
      const apiKey = 'Gemini API Key'; // Gemini API Key
      
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final imageBytes = await _imageFile!.readAsBytes();
      
      final prompt = '''
      You are an intelligent listing assistant for a campus second-hand marketplace.
      Please identify the item in the image and generate a structured product description.
      
      Requirements:
      1. title: Generate a concise and catchy product title (maximum 10 words).
      2. description: Output EXACTLY in this clear, bulleted format. Do not write long paragraphs. 
         Format example:
         Condition : [Score]/10
         - [Key feature 1, e.g., capacity, size, or brand]
         - [Key feature 2, e.g., color or material]
         - [Key feature 3, optional details]
         (Important: Use \\n to represent line breaks within the JSON string).
      3. category: You MUST select exactly one category from the following strict list: Electronics, Books, Clothes, Furniture, Sports & Fitness, Daily Essentials, Leisure & Hobbies, Others.
      - CLASSIFICATION RULES:
           * For 3C digital devices (e.g., phones, laptops, cameras, calculators), choose 'Electronics'.
           * For small home/dorm appliances (e.g., desk lamps, rice cookers, kettles, hair dryers), choose 'Daily Essentials'.
           * For large room items (e.g., chairs, desks, beds), choose 'Furniture'.
      Output STRICTLY in JSON format. Do not include any markdown formatting (such as ```json), explanations, or additional text.
      Use the exact structure below:
      {
        "title": "...",
        "description": "Condition : 8/10\\n- 530ml\\n- Navy Blue",
        "category": "..."
      }
      ''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]);

      final text = response.text;
      if (text != null) {
        final cleanJsonString = text.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJsonString);

        setState(() {
          _titleController.text = data['title'] ?? '';
          _descController.text = data['description'] ?? '';
          
          final aiCategory = data['category'];
          if (_categories.any((c) => c['label'] == aiCategory)) {
            _selectedCategory = aiCategory;
          } else {
            _selectedCategory = 'Others';
          }
        });
        _showSnack('✨ AI auto-fill completed!');
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🕵️ Error Reason'),
          content: SingleChildScrollView(
            child: Text(
              e.toString(),
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            )
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
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
      _showSnack('Upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.blue,
                              size: 26,
                            ),
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
            const SizedBox(height: 16),

            if (_imageFile != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAiLoading ? null : _generateDescriptionWithAi,
                  icon: _isAiLoading 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  label: Text(
                    _isAiLoading ? 'Analyzing image...' : '✨ Auto-fill with AI',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C52FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            _label('Product Name'),
            const SizedBox(height: 8),
            _textField(_titleController, 'e.g. Calculus Textbook 8th Edition'),
            const SizedBox(height: 18),

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

            _label('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: _inputDeco(
                  'Describe condition, brand, year, any defects...'),
            ),
            const SizedBox(height: 18),

            _label('Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.blue : AppColors.inputBg,
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
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
      );
}
