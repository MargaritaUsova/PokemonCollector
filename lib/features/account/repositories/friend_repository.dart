abstract class FriendRepository {
  Future<void> sendFriendRequest(String currentUserId, String targetUserId);
  Future<void> acceptFriendRequest(String currentUserId, String fromUserId);
  Future<void> rejectFriendRequest(String currentUserId, String fromUserId);
  Future<void> cancelFriendRequest(String currentUserId, String targetUserId);
  Future<void> removeFriend(String currentUserId, String friendId);
  Stream<List<String>> getFriendsList(String userId);
  Stream<List<String>> getFriendRequests(String userId);
  Future<List<Map<String, dynamic>>> getOutgoingRequests(String userId);
  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId);
}
