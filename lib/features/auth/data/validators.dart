/// Input validation utilities for form fields and user input
class InputValidator {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain both letters and numbers';
    }

    return null;
  }

  /// Validate phone number format
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove common formatting characters
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's at least 10 digits
    if (!RegExp(r'^\d{10,}$').hasMatch(cleanedPhone)) {
      return 'Please enter a valid phone number (at least 10 digits)';
    }

    return null;
  }

  /// Validate weight in kilograms
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }

    try {
      final weight = double.parse(value);
      if (weight <= 0 || weight > 500) {
        return 'Please enter a valid weight between 1 and 500 kg';
      }
    } catch (e) {
      return 'Weight must be a valid number';
    }

    return null;
  }

  /// Validate height in centimeters
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }

    try {
      final height = double.parse(value);
      if (height <= 0 || height > 300) {
        return 'Please enter a valid height between 1 and 300 cm';
      }
    } catch (e) {
      return 'Height must be a valid number';
    }

    return null;
  }

  /// Validate non-empty required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate name format (first name, last name, etc.)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validate medication name
  static String? validateMedicationName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Medication name is required';
    }

    if (value.length < 2) {
      return 'Medication name must be at least 2 characters long';
    }

    return null;
  }

  /// Validate dosage format
  static String? validateDosage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Dosage is required';
    }

    // Allow patterns like "500mg", "2.5ml", "1 tablet", etc.
    if (!RegExp(r'^[\d.]+\s*[a-zA-Z]+$').hasMatch(value.trim())) {
      return 'Please enter dosage in format like "500mg" or "2 tablets"';
    }

    return null;
  }

  /// Validate frequency format
  static String? validateFrequency(String? value) {
    if (value == null || value.isEmpty) {
      return 'Frequency is required';
    }

    return null;
  }

  /// Get password strength indicator
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return 'None';
    if (password.length < 6) return 'Weak';
    if (password.length < 8) return 'Fair';
    if (RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return 'Strong';
    }
    if (RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      return 'Good';
    }
    return 'Fair';
  }

  /// Check if email is valid (without error message)
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Check if password is valid (without error message)
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// Check if phone is valid (without error message)
  static bool isValidPhone(String phone) {
    final cleanedPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\d{10,}$').hasMatch(cleanedPhone);
  }
}
