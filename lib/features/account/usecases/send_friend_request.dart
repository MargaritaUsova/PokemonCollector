import '../repositories/friend_repository.dart';

class SendFriendRequest {
  final FriendRepository repository;

  SendFriendRequest(this.repository);

  Future<void> call(String currentUserId, String targetUserId) async {
    return await repository.sendFriendRequest(currentUserId, targetUserId);
  }
}
