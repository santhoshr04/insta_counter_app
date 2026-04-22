/// Dummy profile — future: OAuth / Instagram Basic Display API.
class MockProfile {
  const MockProfile({
    required this.displayName,
    required this.email,
  });

  final String displayName;
  final String email;

  static const current = MockProfile(
    displayName: 'Demo User',
    email: 'demo@email.com',
  );
}
