import '../models/profile.dart';

/// Carries "I am signing up as a purohit" across the OTP round-trip.
///
/// Deliberately a plain static holder rather than a provider: the value has to
/// survive sign-in -> verify -> onboarding, and go_router tears those pages
/// (and anything scoped to them) down as the session status changes.
abstract final class AuthIntent {
  static UserRole? _pending;

  /// Pass null to clear — e.g. when the user switches back to plain sign in.
  static void remember(UserRole? role) => _pending = role;

  static UserRole? peek() => _pending;

  /// Reads and clears in one go, so a stale intent can never fire twice.
  static UserRole? take() {
    final role = _pending;
    _pending = null;
    return role;
  }
}
