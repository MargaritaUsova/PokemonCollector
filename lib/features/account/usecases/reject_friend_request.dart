import '../repositories/friend_repository.dart';

class RejectFriendRequest {
  final FriendRepository repository;

  RejectFriendRequest(this.repository);

  Future<void> call(String currentUserId, String fromUserId) async {
    return await repository.rejectFriendRequest(currentUserId, fromUserId);
  }
}
