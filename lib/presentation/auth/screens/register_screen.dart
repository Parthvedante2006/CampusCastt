import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/student_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String? _selectedCollegeId;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool? _isEmailValid;
  String? _emailErrorMessage;

  // The selected section/college ID
  // It will directly map to the Firestore section document ID

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkEmailWhitelist(String email) async {
    if (email.isEmpty || _selectedCollegeId == null) return;
    
    setState(() {
      _isCheckingEmail = true;
      _isEmailValid = null;
      _emailErrorMessage = null;
    });

    try {
      final formattedEmail = email.toLowerCase().replaceAll('@', '_at_').replaceAll('.', '_');
      final doc = await FirebaseFirestore.instance
          .collection('whitelist')
          .doc(_selectedCollegeId)
          .collection('emails')
          .doc(formattedEmail)
          .get();

      if (!doc.exists) {
        setState(() {
          _isEmailValid = false;
          _emailErrorMessage = "Your email is not registered. Contact your college admin.";
        });
      } else {
        final data = doc.data();
        if (data?['is_registered'] == true) {
          setState(() {
            _isEmailValid = false;
            _emailErrorMessage = "Account exists. Please login.";
          });
        } else {
          setState(() {
            _isEmailValid = true;
            _emailErrorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isEmailValid = false;
        _emailErrorMessage = "Error verifying email.";
      });
    } finally {
      setState(() {
        _isCheckingEmail = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.isEmpty || 
        _selectedCollegeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_isEmailValid != true) {
      await _checkEmailWhitelist(_emailController.text.trim());
      if (_isEmailValid != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_emailErrorMessage ?? 'Invalid email validation.'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.registerStudent(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedCollegeId!,
      );

      if (!mounted) return;

      if (user != null) {
        context.go(AppRoutes.studentHome);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // College Dropdown
                      ref.watch(studentSectionsProvider).when(
                        data: (sections) {
                          // Validate selected ID still exists in list, otherwise clear it to prevent Dropdown crash
                          if (_selectedCollegeId != null && !sections.any((s) => s.id == _selectedCollegeId)) {
                            _selectedCollegeId = null; 
                          }
                          return DropdownButtonFormField<String>(
                            value: _selectedCollegeId,
                            dropdownColor: AppColors.cardBg,
                            style: const TextStyle(color: AppColors.white),
                            decoration: InputDecoration(
                              hintText: 'Select College',
                              hintStyle: const TextStyle(color: AppColors.grey),
                              prefixIcon: const Icon(Icons.account_balance, color: AppColors.grey),
                              filled: true,
                              fillColor: AppColors.primaryBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: sections.map((section) {
                              return DropdownMenuItem(
                                value: section.id,
                                child: Text(section.collegeTrust),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCollegeId = value;
                              });
                              if (_emailController.text.isNotEmpty) {
                                 _checkEmailWhitelist(_emailController.text.trim());
                              }
                            },
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: AppColors.accentBlue),
                        ),
                        error: (err, st) => const Text(
                          'Error loading colleges.',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Full Name
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Full Name',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          prefixIcon: const Icon(Icons.person, color: AppColors.grey),
                          filled: true,
                          fillColor: AppColors.primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Email with Validation
                      Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus && _emailController.text.isNotEmpty && _selectedCollegeId != null) {
                            _checkEmailWhitelist(_emailController.text.trim());
                          }
                        },
                        child: TextField(
                          controller: _emailController,
                          style: const TextStyle(color: AppColors.white),
                          decoration: InputDecoration(
                            hintText: 'College Email',
                            hintStyle: const TextStyle(color: AppColors.grey),
                            prefixIcon: const Icon(Icons.email, color: AppColors.grey),
                            suffixIcon: _isCheckingEmail
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                                  )
                                : _isEmailValid == true
                                    ? const Icon(Icons.check_circle, color: AppColors.success)
                                    : _isEmailValid == false
                                        ? const Icon(Icons.error, color: AppColors.error)
                                        : null,
                            filled: true,
                            fillColor: AppColors.primaryBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      if (_emailErrorMessage != null)
                         Padding(
                           padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                           child: Align(
                             alignment: Alignment.centerLeft,
                             child: Text(_emailErrorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                           ),
                         ),
                      const SizedBox(height: 16),
                      // Password
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(color: AppColors.white),
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          prefixIcon: const Icon(Icons.lock, color: AppColors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confirm Password
                      TextField(
                        controller: _confirmPasswordController,
                        style: const TextStyle(color: AppColors.white),
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          hintStyle: const TextStyle(color: AppColors.grey),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: AppColors.white)
                              : const Text(
                                  'Register',
                                  style: TextStyle(fontSize: 18, color: AppColors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
