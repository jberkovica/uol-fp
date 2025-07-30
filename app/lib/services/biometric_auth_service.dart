import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';
import 'logging_service.dart';

/// Service for handling biometric authentication
class BiometricAuthService {
  static BiometricAuthService? _instance;
  static BiometricAuthService get instance => _instance ??= BiometricAuthService._();
  BiometricAuthService._();

  static final _logger = LoggingService.getLogger('BiometricAuthService');
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available
  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      _logger.e('Error checking biometric availability', error: e);
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('Error getting available biometrics', error: e);
      return [];
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Biometric authentication required',
            cancelButton: 'Cancel',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
          ),
        ],
        options: AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: stickyAuth,
          useErrorDialogs: useErrorDialogs,
        ),
      );

      _logger.i('Biometric authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      _logger.e('Biometric authentication error', error: e);
      
      // Handle specific error cases
      switch (e.code) {
        case 'NotAvailable':
          _logger.w('Biometric authentication not available');
          break;
        case 'NotEnrolled':
          _logger.w('No biometrics enrolled on device');
          break;
        case 'LockedOut':
          _logger.w('Biometric authentication locked out');
          break;
        case 'PermanentlyLockedOut':
          _logger.w('Biometric authentication permanently locked out');
          break;
        default:
          _logger.e('Unknown biometric error: ${e.code}');
      }
      
      return false;
    } catch (e) {
      _logger.e('Unexpected biometric authentication error', error: e);
      return false;
    }
  }

  /// Stop biometric authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      _logger.e('Error stopping biometric authentication', error: e);
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong biometric';
      case BiometricType.weak:
        return 'Weak biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get primary biometric type available on device
  Future<BiometricType?> getPrimaryBiometricType() async {
    final availableBiometrics = await getAvailableBiometrics();
    
    if (availableBiometrics.isEmpty) return null;
    
    // Prioritize face recognition, then fingerprint
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else {
      return availableBiometrics.first;
    }
  }

  /// Check if device has strong biometric authentication
  Future<bool> hasStrongBiometric() async {
    final availableBiometrics = await getAvailableBiometrics();
    return availableBiometrics.contains(BiometricType.strong) ||
           availableBiometrics.contains(BiometricType.face) ||
           availableBiometrics.contains(BiometricType.fingerprint);
  }
}