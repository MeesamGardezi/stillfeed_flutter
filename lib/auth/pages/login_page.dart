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
import '../models/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    globalAuthNotifier.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    globalAuthNotifier.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;

    setState(() {
      _isLoading = globalAuthNotifier.value.status == AuthStatus.loading;
    });

    if (globalAuthNotifier.value.status == AuthStatus.authenticated) {
      context.go(AppRoutes.feed);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await globalAuthNotifier.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          Helpers.getErrorMessage(e) ?? AppStrings.loginFailed,
          isError: true,
        );
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
            Icons.nature_people,
            size: AppDimensions.iconXLarge + 8,
            color: AppColors.accentGreen,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            AppStrings.appName,
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
            AppStrings.appTagline,
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
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          CustomTextField(
            label: AppStrings.password,
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outlined,
            validator: Validators.validatePassword,
            focusNode: _passwordFocusNode,
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(AppRoutes.forgotPassword),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSmall,
                  vertical: AppDimensions.paddingXSmall,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppStrings.forgotPassword,
                style: TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: AppDimensions.fontSmall,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          CustomButton(
            text: AppStrings.login,
            onPressed: _handleLogin,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.dontHaveAccount,
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.signup),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSmall,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.signup,
                  style: TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: AppDimensions.fontSmall,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}