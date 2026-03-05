import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: AppColors.white)),
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Admin Profile — Coming Soon', style: TextStyle(color: AppColors.grey, fontSize: 16)),
      ),
    );
  }
}
