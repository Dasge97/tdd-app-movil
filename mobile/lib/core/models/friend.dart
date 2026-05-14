import 'user.dart';

class Friend {
  final int id;
  final User requester;
  final User addressee;
  final String status;
  final DateTime createdAt;

  const Friend({
    required this.id,
    required this.requester,
    required this.addressee,
    required this.status,
    required this.createdAt,
  });

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'] as int,
        requester:
            User.fromJson(j['requester'] as Map<String, dynamic>),
        addressee:
            User.fromJson(j['addressee'] as Map<String, dynamic>),
        status: j['status'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
