import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

class BottomNavBar extends StatelessWidget {
  final String currentPath;

  const BottomNavBar({
    super.key,
    required this.currentPath,
  });

  int _getCurrentIndex() {
    switch (currentPath) {
      case '/':
        return 0;
      case '/following-feed':
        return 1;
      case '/upload':
        return 2;
      case '/profile':
        return 3;
      case '/settings':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: NavigationBar(
            selectedIndex: _getCurrentIndex(),
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go(AppRoutes.feed);
                  break;
                case 1:
                  context.go(AppRoutes.followingFeed);
                  break;
                case 2:
                  context.push(AppRoutes.uploadVideo);
                  break;
                case 3:
                  context.go(AppRoutes.profile);
                  break;
                case 4:
                  context.go(AppRoutes.settings);
                  break;
              }
            },
            backgroundColor: AppColors.backgroundPrimary,
            indicatorColor: AppColors.accentGreen.withOpacity(0.08),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: AppDimensions.bottomNavHeight,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  size: AppDimensions.iconMedium,
                ),
                selectedIcon: Icon(
                  Icons.home,
                  size: AppDimensions.iconMedium,
                  color: AppColors.accentGreen,
                ),
                label: 'Feed',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.people_outline,
                  size: AppDimensions.iconMedium,
                ),
                selectedIcon: Icon(
                  Icons.people,
                  size: AppDimensions.iconMedium,
                  color: AppColors.accentGreen,
                ),
                label: 'Following',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.add_circle_outline,
                  size: AppDimensions.iconLarge,
                ),
                selectedIcon: Icon(
                  Icons.add_circle,
                  size: AppDimensions.iconLarge,
                  color: AppColors.accentGreen,
                ),
                label: 'Upload',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  size: AppDimensions.iconMedium,
                ),
                selectedIcon: Icon(
                  Icons.person,
                  size: AppDimensions.iconMedium,
                  color: AppColors.accentGreen,
                ),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.settings_outlined,
                  size: AppDimensions.iconMedium,
                ),
                selectedIcon: Icon(
                  Icons.settings,
                  size: AppDimensions.iconMedium,
                  color: AppColors.accentGreen,
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}