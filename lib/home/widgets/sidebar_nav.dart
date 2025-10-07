import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/services/auth_notifier.dart';

class SidebarNav extends StatelessWidget {
  final String currentPath;

  const SidebarNav({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          right: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.paddingMedium,
                horizontal: AppDimensions.paddingSmall,
              ),
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Feed',
                  path: AppRoutes.feed,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Following',
                  path: AppRoutes.followingFeed,
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                Divider(
                  color: AppColors.divider,
                  height: 1,
                  indent: AppDimensions.paddingSmall,
                  endIndent: AppDimensions.paddingSmall,
                ),
                const SizedBox(height: AppDimensions.paddingSmall),
                _buildNavItem(
                  context,
                  icon: Icons.video_library_outlined,
                  activeIcon: Icons.video_library,
                  label: 'Saved Videos',
                  path: AppRoutes.savedVideos,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  path: AppRoutes.profile,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  path: AppRoutes.settings,
                ),
              ],
            ),
          ),
          _buildUploadButton(context),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: AppDimensions.appBarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.nature_people,
            color: AppColors.accentGreen,
            size: AppDimensions.iconLarge,
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Text(
            AppStrings.appName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontHeading,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String path,
  }) {
    final isActive = currentPath == path;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingXSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: isActive 
                  ? AppColors.accentGreen.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: AppDimensions.iconMedium,
                  color: isActive 
                      ? AppColors.accentGreen 
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.paddingMedium),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppDimensions.fontMedium,
                    color: isActive 
                        ? AppColors.accentGreen 
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: SizedBox(
        height: AppDimensions.buttonHeight,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push(AppRoutes.uploadVideo),
          icon: Icon(
            Icons.add_circle_outline,
            size: AppDimensions.iconMedium,
          ),
          label: Text(
            'Upload Video',
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: AppColors.textOnAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMedium,
        0,
        AppDimensions.paddingMedium,
        AppDimensions.paddingMedium,
      ),
      child: SizedBox(
        height: AppDimensions.buttonHeight,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await Helpers.showConfirmDialog(
              context,
              'Log Out',
              'Are you sure you want to log out?',
            );

            if (confirm == true && context.mounted) {
              final authNotifier = AuthNotifier();
              await authNotifier.signOut();
              authNotifier.dispose();
            }
          },
          icon: Icon(
            Icons.logout,
            size: AppDimensions.iconMedium,
          ),
          label: Text(
            'Log Out',
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(
              color: AppColors.borderMedium,
              width: 1,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}