import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_router.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/admin_provider.dart';

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

  String? _selectedSectionId;
  String? _selectedSectionName;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isCheckingEmail = false;
  bool? _isEmailValid;
  String? _emailErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Check email against whitelist using correct sanitization
  Future<void> _checkEmailWhitelist(String email) async {
    if (email.isEmpty || _selectedSectionId == null) {
      setState(() {
        _isEmailValid = null;
        _emailErrorMessage =
            _selectedSectionId == null ? 'Please select your college first.' : null;
      });
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _isEmailValid = false;
        _emailErrorMessage = 'Please enter a valid email.';
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
      _isEmailValid = null;
      _emailErrorMessage = null;
    });

    try {
      // ✅ Use adminRepository which uses correct sanitization
      final result = await ref
          .read(adminRepositoryProvider)
          .checkStudentWhitelist(
            email: email.trim().toLowerCase(),
            sectionId: _selectedSectionId!,
          );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isEmailValid = false;
          _emailErrorMessage =
              '❌ Email not found. Contact your college admin.';
        });
      } else if (result['is_registered'] == true) {
        setState(() {
          _isEmailValid = false;
          _emailErrorMessage =
              '⚠️ Already registered. Please login instead.';
        });
      } else {
        setState(() {
          _isEmailValid = true;
          _emailErrorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEmailValid = false;
        _emailErrorMessage = 'Error verifying email. Try again.';
      });
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  Future<void> _handleRegister() async {
    // ── Validation ─────────────────────────────────────────
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (_selectedSectionId == null) {
      _showError('Please select your college.');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter your email.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password.');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }

    // ── Re-check whitelist if not already validated ────────
    if (_isEmailValid != true) {
      await _checkEmailWhitelist(_emailController.text.trim());
      if (_isEmailValid != true) {
        _showError(_emailErrorMessage ?? 'Email not authorized.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);

      // ✅ Register in Firebase Auth + create user doc
      final user = await repository.registerStudent(
        _nameController.text.trim(),
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
        _selectedSectionId!,
      );

      if (!mounted) return;

      if (user != null) {
        // ✅ Mark as registered in whitelist
        await ref
            .read(adminRepositoryProvider)
            .markStudentRegistered(
              email: _emailController.text.trim().toLowerCase(),
              sectionId: _selectedSectionId!,
            );

        if (!mounted) return;
        context.go(AppRoutes.studentHome);
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      // Clean up Firebase error messages
      if (errorMsg.contains('email-already-in-use')) {
        errorMsg = 'This email is already registered. Please login.';
      } else if (errorMsg.contains('weak-password')) {
        errorMsg = 'Password is too weak. Use at least 6 characters.';
      } else if (errorMsg.contains('invalid-email')) {
        errorMsg = 'Invalid email address.';
      }
      _showError(errorMsg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Fetch real sections from Firestore
    final sectionsAsync = ref.watch(sectionsStreamProvider);

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
                // ── Header ───────────────────────────────
                const Icon(Icons.school_rounded,
                    color: AppColors.accentBlue, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Register with your college email',
                  style: TextStyle(
                      color: AppColors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white10, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── College Dropdown (from Firestore) ──
                      const Text('Select College',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      sectionsAsync.when(
                        loading: () => Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.accentBlue,
                                strokeWidth: 2),
                          ),
                        ),
                        error: (e, _) => Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                                'Failed to load colleges',
                                style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13)),
                          ),
                        ),
                        data: (sections) {
                          if (sections.isEmpty) {
                            return Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBg,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                    'No colleges available yet',
                                    style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 13)),
                              ),
                            );
                          }
                          return DropdownButtonFormField<String>(
                            value: _selectedSectionId,
                            dropdownColor: AppColors.cardBg,
                            style: const TextStyle(
                                color: AppColors.white),
                            decoration: InputDecoration(
                              hintText: 'Select your college',
                              hintStyle: const TextStyle(
                                  color: AppColors.grey),
                              prefixIcon: const Icon(
                                  Icons.account_balance,
                                  color: AppColors.grey),
                              filled: true,
                              fillColor: AppColors.primaryBg,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            // ✅ Real sections from Firestore
                            items: sections.map((section) {
                              return DropdownMenuItem(
                                value: section.id,
                                child: Text(section.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              final selected = sections
                                  .firstWhere((s) => s.id == value);
                              setState(() {
                                _selectedSectionId = value;
                                _selectedSectionName =
                                    selected.name;
                                // Reset email validation on section change
                                _isEmailValid = null;
                                _emailErrorMessage = null;
                              });
                              // Re-check email if already entered
                              if (_emailController.text
                                  .isNotEmpty) {
                                _checkEmailWhitelist(
                                    _emailController.text.trim());
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Full Name ───────────────────────
                      const Text('Full Name',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                            color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: const TextStyle(
                              color: AppColors.grey),
                          prefixIcon: const Icon(Icons.person,
                              color: AppColors.grey),
                          filled: true,
                          fillColor: AppColors.primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Email with Check button ─────────
                      const Text('College Email',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              style: const TextStyle(
                                  color: AppColors.white),
                              keyboardType:
                                  TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'your@college.edu',
                                hintStyle: const TextStyle(
                                    color: AppColors.grey),
                                prefixIcon: const Icon(
                                    Icons.email,
                                    color: AppColors.grey),
                                suffixIcon: _isCheckingEmail
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.all(12.0),
                                        child:
                                            CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors
                                                    .accentBlue),
                                      )
                                    : _isEmailValid == true
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: AppColors.success)
                                        : _isEmailValid == false
                                            ? const Icon(
                                                Icons.cancel,
                                                color: AppColors.error)
                                            : null,
                                filled: true,
                                fillColor: AppColors.primaryBg,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _isEmailValid == true
                                        ? AppColors.success
                                        : _isEmailValid == false
                                            ? AppColors.error
                                            : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ✅ Check button
                          GestureDetector(
                            onTap: _isCheckingEmail
                                ? null
                                : () => _checkEmailWhitelist(
                                    _emailController.text.trim()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.accentBlue,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text('Check',
                                  style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                          ),
                        ],
                      ),
                      // Error message
                      if (_emailErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, left: 4.0),
                          child: Text(
                            _emailErrorMessage!,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12),
                          ),
                        ),
                      // Success message
                      if (_isEmailValid == true)
                        const Padding(
                          padding:
                              EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text(
                            '✅ Email verified! You can register.',
                            style: TextStyle(
                                color: AppColors.success,
                                fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // ── Password ────────────────────────
                      const Text('Password',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        style: const TextStyle(
                            color: AppColors.white),
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Minimum 6 characters',
                          hintStyle: const TextStyle(
                              color: AppColors.grey),
                          prefixIcon: const Icon(Icons.lock,
                              color: AppColors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.grey,
                            ),
                            onPressed: () => setState(() =>
                                _obscurePassword =
                                    !_obscurePassword),
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

                      // ── Confirm Password ────────────────
                      const Text('Confirm Password',
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmPasswordController,
                        style: const TextStyle(
                            color: AppColors.white),
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          hintStyle: const TextStyle(
                              color: AppColors.grey),
                          prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.grey,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          filled: true,
                          fillColor: AppColors.primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Register Button ─────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2)
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.white,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Login Link ──────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                      color: AppColors.accentBlue,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ],
                            ),
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