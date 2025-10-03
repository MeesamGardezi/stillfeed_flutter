import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../widgets/sidebar_nav.dart';
import '../widgets/bottom_nav_bar.dart';

class MainLayoutPage extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainLayoutPage({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 600;

    if (isWeb) {
      return _buildWebLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SidebarNav(currentPath: currentPath),
          Expanded(
            child: Container(
              color: AppColors.backgroundLight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(currentPath: currentPath),
    );
  }
}