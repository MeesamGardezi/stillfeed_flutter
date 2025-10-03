class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Display name is required';
    }
    
    if (value.length < 2 || value.length > 30) {
      return 'Display name must be between 2 and 30 characters';
    }
    
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s_-]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Display name can only contain letters, numbers, spaces, hyphens, and underscores';
    }
    
    return null;
  }

  static String? validateBio(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    
    if (value.length > 150) {
      return 'Bio must not exceed 150 characters';
    }
    
    return null;
  }

  static String? validateVideoTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }
    
    if (value.length < 5 || value.length > 60) {
      return 'Title must be between 5 and 60 characters';
    }
    
    if (value == value.toUpperCase() && value.replaceAll(RegExp(r'[^a-zA-Z]'), '').length > 3) {
      return 'Title cannot be in ALL CAPS';
    }
    
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < 50 || value.length > 500) {
      return 'Description must be between 50 and 500 characters';
    }
    
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}