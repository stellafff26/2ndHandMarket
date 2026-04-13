import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_input.dart';
import '../widgets/app_button.dart';
import '../widgets/campuswap_logo.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  String? _selectedUniversity;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmailValid = false; 

  final List<String> _universities = [
    'Universiti Malaya (UM)',
    'Universiti Kebangsaan Malaysia (UKM)',
    'Universiti Putra Malaysia (UPM)',
    'Universiti Sains Malaysia (USM)',
    'Universiti Teknologi Malaysia (UTM)',
    'Universiti Teknologi MARA (UiTM)',
    'Universiti Islam Antarabangsa Malaysia (UIAM)',
    'Universiti Utara Malaysia (UUM)',
    'Universiti Malaysia Sabah (UMS)',
    'Universiti Malaysia Sarawak (UNIMAS)',
  ];

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    final email = _emailController.text;
    final bool isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (_isEmailValid != isValid) {
      setState(() {
        _isEmailValid = isValid;
      });
    }
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedUniversity == null) {
      _showSnack('Please fill in all fields');
      return;
    }

    if (!_isEmailValid) {
      _showSnack('Please enter a valid email address');
      return;
    }

    final password = _passwordController.text.trim();
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    if (password.length < 8 || !hasLetter || !hasNumber) {
      _showSnack('Password must be at least 8 characters with letters and numbers');
      return;
    }

    setState(() => _isLoading = true);
    final error = await _authService.register(
      name: _nameController.text,
      email: _emailController.text,
      password: password,
      university: _selectedUniversity!,
    );
    setState(() => _isLoading = false);
    
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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
    _emailController.removeListener(_validateEmail); 
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 39),
              const Center(child: CampuSwapLogo(size: 100)),
              const SizedBox(height: 20), 

              const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Join your campus marketplace',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Name
              AppInput(
                controller: _nameController,
                label: 'Full Name',
                hint: 'e.g. Angel Lim',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              // Email
              AppInput(
                controller: _emailController,
                label: 'Email',
                hint: 'your email',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                suffix: _emailController.text.isNotEmpty
                    ? Icon(
                        _isEmailValid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        color: _isEmailValid ? Colors.green : Colors.red,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // Password
              AppInput(
                controller: _passwordController,
                label: 'Password',
                hint: 'min. 8 chars (letters & numbers)', 
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),

              // University dropdown 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UNIVERSITY',
                    style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.w700,
                      color: AppColors.campuDark,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedUniversity,
                    hint: const Text(
                      'Select your university',
                      style: TextStyle(color: AppColors.textHint, fontSize: 14),
                    ),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.campuDark),
                    dropdownColor: Colors.white,
                    items: _universities
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u,
                                  style: const TextStyle(
                                      fontSize: 14, 
                                      color: AppColors.textPrimary)),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedUniversity = val),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputBg,
                      
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      prefixIcon: Icon(
                        Icons.school_outlined, 
                        size: 18,
                        color: AppColors.campuDark.withOpacity(0.45),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _selectedUniversity != null
                              ? AppColors.blue
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.blue, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Create account',
                onPressed: _register,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

