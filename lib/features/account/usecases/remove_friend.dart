import '../repositories/friend_repository.dart';

class RemoveFriend {
  final FriendRepository repository;

  RemoveFriend(this.repository);

  Future<void> call(String currentUserId, String friendId) async {
    return await repository.removeFriend(currentUserId, friendId);
  }
}
