/// Returns true when [token] looks like a real JWT from the API (not guest/legacy).
bool isValidApiJwt(String? token) {
  if (token == null || token.isEmpty) return false;
  if (token == 'guest-token') return false;
  if (token.contains(':')) return false; // phone:, master:, admin:, user:
  final parts = token.split('.');
  return parts.length == 3 && parts.every((p) => p.isNotEmpty);
}
