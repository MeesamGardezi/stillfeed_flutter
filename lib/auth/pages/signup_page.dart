import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../core/widgets/custom_textfield.dart';
import '../models/auth_state.dart';
import '../services/auth_notifier';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();
  final _displayNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _bioFocusNode = FocusNode();
  late final AuthNotifier _authNotifier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthNotifier();
    _authNotifier.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authNotifier.removeListener(_onAuthStateChanged);
    _authNotifier.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _displayNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;

    setState(() {
      _isLoading = _authNotifier.value.status == AuthStatus.loading;
    });

    if (_authNotifier.value.status == AuthStatus.authenticated) {
      context.go(AppRoutes.feed);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _authNotifier.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          Helpers.getErrorMessage(e) ?? AppStrings.signupFailed,
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
              maxWidth: 400,
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
            Icons.person_add,
            size: AppDimensions.iconXLarge,
            color: AppColors.accentGreen,
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            AppStrings.signup,
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
            'Join ${AppStrings.appName}',
            style: TextStyle(
              fontSize: AppDimensions.fontMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingXLarge),
          CustomTextField(
            label: AppStrings.displayName,
            controller: _displayNameController,
            prefixIcon: Icons.person_outlined,
            validator: Validators.validateDisplayName,
            focusNode: _displayNameFocusNode,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_emailFocusNode);
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          CustomTextField(
            label: AppStrings.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Validators.validateEmail,
            focusNode: _emailFocusNode,
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
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_bioFocusNode);
            },
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          CustomTextField(
            label: '${AppStrings.bio} (optional)',
            hint: 'Tell us about yourself',
            controller: _bioController,
            maxLines: 3,
            maxLength: 150,
            validator: Validators.validateBio,
            focusNode: _bioFocusNode,
            onFieldSubmitted: (_) => _handleSignup(),
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          CustomButton(
            text: AppStrings.signup,
            onPressed: _handleSignup,
            isLoading: _isLoading,
          ),
          const SizedBox(height: AppDimensions.paddingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.alreadyHaveAccount,
                style: TextStyle(
                  fontSize: AppDimensions.fontSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSmall,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.login,
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