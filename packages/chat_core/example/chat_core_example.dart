import 'package:chat_core/chat_core.dart';

void main() {
  final user = User(
    id: '01HZZZZ',
    username: 'alice',
    displayName: 'Alice',
    createdAt: DateTime.now(),
  );
  print('User: ${user.displayName}');
  print('Constants: ${ApiConstants.defaultBaseUrl}');
}
