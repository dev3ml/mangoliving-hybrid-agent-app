import 'models/agent_user.dart';

/// Client-side checks for agent signup. The server still validates the same
/// fields on `POST /v1/auth/signup`.
abstract final class SignupForm {
  static final RegExp _license = RegExp(r'^[A-Za-z]{0,3}[-\s]?\w{4,15}$');

  static String sanitizeName(String value) {
    return value
        .replaceAll(RegExp(r"[^A-Za-z\s'-]"), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .replaceAll(RegExp(r'^ +'), '');
  }

  static ({String firstName, String lastName}) splitName(String name) {
    final List<String> parts =
        name.trim().split(RegExp(r'\s+')).where((String part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return (firstName: '', lastName: '');
    return (firstName: parts.first, lastName: parts.skip(1).join(' '));
  }

  static String digitsOnly(String value, {int max = 10}) {
    final String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= max) return digits;
    return digits.substring(0, max);
  }

  static bool passwordIsStrongEnough(String password) {
    final int hits = <bool>[
      password.length >= 8,
      RegExp(r'[a-z]').hasMatch(password),
      RegExp(r'[A-Z]').hasMatch(password),
      RegExp(r'\d').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ].where((bool ok) => ok).length;
    return hits >= 3;
  }

  static bool isLicenseNumber(String value) {
    return _license.hasMatch(value.trim());
  }

  static String? validateName(String value) {
    final String name = value.trim();
    if (name.isEmpty) return 'Enter your full name';
    if (RegExp(r'\d').hasMatch(name)) return 'Name cannot contain numbers';
    return null;
  }

  static String? validateEmail(String value) {
    final String email = value.trim();
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validateMobile(String value) {
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Mobile number must be exactly 10 digits';
    }
    return null;
  }

  static String? validatePassword(String value) {
    if (!passwordIsStrongEnough(value)) {
      return 'Password is too weak. Use at least 8 characters with mixed case, a number, and a symbol.';
    }
    return null;
  }

  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return 'Re-enter your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  static String? validateLicense(String value) {
    if (!isLicenseNumber(value)) return 'Enter a valid Real Estate Agent ID';
    return null;
  }
}

/// Result of creating an agent account inside the app.
final class SignupOutcome {
  const SignupOutcome({required this.session, this.licenseWarning});

  final AgentSession session;
  final String? licenseWarning;
}
