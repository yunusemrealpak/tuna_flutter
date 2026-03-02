import 'package:tuna_chat/tuna_chat.dart';

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
