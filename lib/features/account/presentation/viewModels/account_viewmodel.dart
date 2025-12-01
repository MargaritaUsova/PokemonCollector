import 'package:flutter/foundation.dart';
import '../../repositories/friend_repository.dart';
import '../../usecases/accept_friend_request.dart';
import '../../usecases/reject_friend_request.dart';
import '../../usecases/remove_friend.dart';
import '../../usecases/send_friend_request.dart';

class AccountViewModel extends ChangeNotifier {
  final FriendRepository _repository;
  final SendFriendRequest _sendFriendRequest;
  final AcceptFriendRequest _acceptFriendRequest;
  final RejectFriendRequest _rejectFriendRequest;
  final RemoveFriend _removeFriend;

  AccountViewModel(this._repository)
      : _sendFriendRequest = SendFriendRequest(_repository),
        _acceptFriendRequest = AcceptFriendRequest(_repository),
        _rejectFriendRequest = RejectFriendRequest(_repository),
        _removeFriend = RemoveFriend(_repository);

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  String? _successMessage;

  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _searchResults = await _repository.searchUsers(query, currentUserId);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка поиска: $e';
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    try {
      await _sendFriendRequest(currentUserId, targetUserId);
      _successMessage = 'Запрос на добавление в друзья отправлен';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка при отправке запроса: $e';
      notifyListeners();
    }
  }

  Future<void> acceptFriendRequest(String currentUserId, String fromUserId) async {
    try {
      await _acceptFriendRequest(currentUserId, fromUserId);
      _successMessage = 'Пользователь добавлен в друзья';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка: $e';
      notifyListeners();
    }
  }

  Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      await _removeFriend(currentUserId, friendId);
      _successMessage = 'Пользователь удален из друзей';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка при удалении: $e';
      notifyListeners();
    }
  }

  Future<void> rejectFriendRequest(String currentUserId, String fromUserId) async {
    try {
      await _rejectFriendRequest(currentUserId, fromUserId);
      _successMessage = 'Запрос отклонен';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка: $e';
      notifyListeners();
    }
  }

  Future<void> cancelFriendRequest(String currentUserId, String targetUserId) async {
    try {
      await _repository.cancelFriendRequest(currentUserId, targetUserId);
      _successMessage = 'Запрос отменен';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Ошибка: $e';
      notifyListeners();
    }
  }

  Stream<List<String>> getFriendsList(String userId) {
    return _repository.getFriendsList(userId);
  }

  Stream<List<String>> getFriendRequests(String userId) {
    return _repository.getFriendRequests(userId);
  }

  Future<List<Map<String, dynamic>>> getOutgoingRequests(String userId) {
    return _repository.getOutgoingRequests(userId);
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
