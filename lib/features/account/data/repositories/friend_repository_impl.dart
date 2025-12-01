import 'package:cloud_firestore/cloud_firestore.dart';
import '../../repositories/friend_repository.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(targetUserId).set({
      'friendRequests': FieldValue.arrayUnion([currentUserId])
    }, SetOptions(merge: true));
  }

  @override
  Future<void> acceptFriendRequest(String currentUserId, String fromUserId) async {
    final batch = _firestore.batch();

    // Текущему пользователю
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'friends': FieldValue.arrayUnion([fromUserId]),
      'friendRequests': FieldValue.arrayRemove([fromUserId]),
    });

    // Отправителю запроса
    batch.update(_firestore.collection('users').doc(fromUserId), {
      'friends': FieldValue.arrayUnion([currentUserId]),
      'friendRequests': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }

  @override
  Future<void> removeFriend(String currentUserId, String friendId) async {
    final batch = _firestore.batch();

    // Удаляем друг друга из списков друзей
    batch.update(_firestore.collection('users').doc(currentUserId), {
      'friends': FieldValue.arrayRemove([friendId]),
    });

    batch.update(_firestore.collection('users').doc(friendId), {
      'friends': FieldValue.arrayRemove([currentUserId]),
    });

    await batch.commit();
  }

  @override
  Future<void> rejectFriendRequest(String currentUserId, String fromUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'friendRequests': FieldValue.arrayRemove([fromUserId])
    });
  }

  @override
  Future<void> cancelFriendRequest(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(targetUserId).update({
      'friendRequests': FieldValue.arrayRemove([currentUserId])
    });
  }

  @override
  Stream<List<String>> getFriendsList(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      return List<String>.from(data?['friends'] ?? []);
    });
  }

  @override
  Stream<List<String>> getFriendRequests(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      return List<String>.from(data?['friendRequests'] ?? []);
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getOutgoingRequests(String userId) async {
    final querySnapshot = await _firestore.collection('users').get();

    return querySnapshot.docs.where((doc) {
      final data = doc.data();
      final friendRequests = List<String>.from(data['friendRequests'] ?? []);
      return friendRequests.contains(userId);
    }).map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'displayName': data['displayName'] ?? 'Unknown',
        'email': data['email'] ?? '',
        'photoURL': data['photoURL'],
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) return [];

    final querySnapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(10)
        .get();

    return querySnapshot.docs
        .where((doc) => doc.id != currentUserId)
        .map((doc) => {
      'uid': doc.id,
      'displayName': doc.data()['displayName'] ?? 'Unknown',
      'email': doc.data()['email'] ?? '',
      'photoURL': doc.data()['photoURL'],
    })
        .toList();
  }
}
