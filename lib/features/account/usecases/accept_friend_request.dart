import '../repositories/friend_repository.dart';

class AcceptFriendRequest {
  final FriendRepository repository;

  AcceptFriendRequest(this.repository);

  Future<void> call(String currentUserId, String fromUserId) async {
    return await repository.acceptFriendRequest(currentUserId, fromUserId);
  }
}
