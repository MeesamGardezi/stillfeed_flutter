import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/router_config.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../core/widgets/custom_textfield.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await globalAuthNotifier.sendPasswordReset(_emailController.text.trim());
      
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Password reset email sent. Please check your inbox.',
        );
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          Helpers.getErrorMessage(e) ?? 'Failed to send reset email',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width >= 600;
    
    return Scaffold(
      backgroundColor: isWeb 
          ? AppColors.backgroundSecondary 
          : AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: AppDimensions.iconMedium,
          ),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ResponsiveLayout(
              maxWidth: 380,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb 
                      ? AppDimensions.paddingXLarge 
                      : AppDimensions.paddingLarge,
                  vertical: AppDimensions.paddingLarge,
                ),
                child: isWeb ? _buildWebLayout() : _buildMobileLayout(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout() {
    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        side: BorderSide(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      color: AppColors.backgroundPrimary,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXLarge),
        child: _buildForm(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return _buildForm();
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_reset,
            size: AppDimensions.iconXLarge,
            color: AppColors.accentGreen,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            AppStrings.resetPassword,
            style: TextStyle(
              fontSize: AppDimensions.fontDisplay,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Text(
            'Enter your email to receive a password reset link',
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingXLarge),
          CustomTextField(
            label: AppStrings.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.validateEmail,
            focusNode: _emailFocusNode,
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: AppStrings.sendResetLink,
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingSmall,
                vertical: AppDimensions.paddingSmall,
              ),
            ),
            child: Text(
              'Back to ${AppStrings.login}',
              style: TextStyle(
                color: AppColors.accentGreen,
                fontSize: AppDimensions.fontSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}