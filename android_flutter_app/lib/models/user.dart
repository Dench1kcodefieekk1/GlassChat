/// Active session user + contacts.
class User {
  final String id;
  final String name;
  final String username;
  final String phone;
  final String bio;
  final String userIdTag;
  final String registrationLabel;
  final bool isVerified;
  final bool isOnline;
  final String lastSeenLabel;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.phone,
    this.bio = '',
    this.userIdTag = '',
    this.registrationLabel = 'August 2026',
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeenLabel = 'last seen recently',
  });
}
