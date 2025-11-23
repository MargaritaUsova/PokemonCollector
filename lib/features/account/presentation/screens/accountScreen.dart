import 'package:flutter/material.dart';
import 'package:pokemon_collector/features/auth/presentation/viewModels/authViewModel.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../friendCollection/presentation/friendCollectionScreen.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _searchResults = querySnapshot.docs
            .where((doc) => doc.id != currentUser?.uid)
            .map((doc) => {
          'uid': doc.id,
          'displayName': doc.data()['displayName'] ?? 'Unknown',
          'email': doc.data()['email'] ?? '',
          'photoURL': doc.data()['photoURL'],
        })
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'friendRequests': FieldValue.arrayUnion([currentUser.uid])
      }, SetOptions(merge: true));

      _showMessage('Запрос на добавление в друзья отправлен');
    } catch (e) {
      print('Error sending friend request: $e');
      _showMessage('Ошибка при отправке запроса', isError: true);
    }
  }

  Future<void> _acceptFriendRequest(String fromUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'friends': FieldValue.arrayUnion([fromUserId]),
        'friendRequests': FieldValue.arrayRemove([fromUserId]),
      });

      await FirebaseFirestore.instance.collection('users').doc(fromUserId).update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });

      _showMessage('Пользователь добавлен в друзья', isSuccess: true);
    } catch (e) {
      print('Error accepting friend request: $e');
      _showMessage('Ошибка: $e', isError: true);
    }
  }

  Future<void> _rejectFriendRequest(String fromUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'friendRequests': FieldValue.arrayRemove([fromUserId])
      });

      _showMessage('Запрос отклонен');
    } catch (e) {
      print('Error rejecting friend request: $e');
    }
  }

  void _showMessage(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
            ? Colors.red
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(authVM, currentUser),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchField(),
                if (_isSearching)
                  _buildLoadingIndicator()
                else if (_searchResults.isNotEmpty)
                  _SearchResultsList(
                    results: _searchResults,
                    onSendRequest: _sendFriendRequest,
                  )
                else if (_searchController.text.isEmpty)
                    _buildTabsSection(currentUser?.uid ?? '')
                  else
                    _buildEmptySearchState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AuthViewModel authVM, User? currentUser) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD56F),
                    Color(0xFFFFF3B0),
                    Colors.amber.shade200,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _buildAvatar(currentUser),
                  SizedBox(height: 12),
                  Text(
                    currentUser?.displayName ?? 'Пользователь',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            authVM.signOut();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(User? currentUser) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        backgroundImage:
        currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
        child: currentUser?.photoURL == null
            ? Icon(Icons.person, size: 50, color: Colors.grey[600])
            : null,
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Поиск пользователей...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _searchUsers('');
            },
          )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: _searchUsers,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptySearchState() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Text('Пользователи не найдены'),
    );
  }

  Widget _buildTabsSection(String userId) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.amber.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.amber.shade700,
          tabs: [
            Tab(text: 'Друзья'),
            Tab(text: 'Запросы'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _FriendsList(userId: userId),
              _FriendRequestsList(
                userId: userId,
                onAccept: _acceptFriendRequest,
                onReject: _rejectFriendRequest,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final Function(String) onSendRequest;

  const _SearchResultsList({
    required this.results,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return ListTile(
          leading: _buildAvatar(user['photoURL']),
          title: Text(user['displayName']),
          subtitle: Text(user['email']),
          trailing: IconButton(
            icon: Icon(Icons.person_add, color: Colors.amber.shade700),
            onPressed: () => onSendRequest(user['uid']),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? photoURL) {
    return CircleAvatar(
      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
      child: photoURL == null ? Icon(Icons.person) : null,
    );
  }
}

class _FriendsList extends StatelessWidget {
  final String userId;

  const _FriendsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final friendIds = List<String>.from(data?['friends'] ?? []);

        if (friendIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            message: 'У вас пока нет друзей',
          );
        }

        return ListView.builder(
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            return _FriendTile(friendId: friendIds[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String friendId;

  const _FriendTile({required this.friendId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(title: Text('Загрузка...'));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: _buildAvatar(data?['photoURL']),
            title: Text(data?['displayName'] ?? 'Unknown'),
            subtitle: Text(data?['email'] ?? ''),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _openFriendCollection(context, data),
          ),
        );
      },
    );
  }

  void _openFriendCollection(BuildContext context, Map<String, dynamic>? data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendCollectionScreen(
          friendId: friendId,
          friendName: data?['displayName'] ?? 'Unknown',
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoURL) {
    return CircleAvatar(
      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
      child: photoURL == null ? Icon(Icons.person) : null,
    );
  }
}

class _FriendRequestsList extends StatelessWidget {
  final String userId;
  final Function(String) onAccept;
  final Function(String) onReject;

  const _FriendRequestsList({
    required this.userId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final requestIds = List<String>.from(data?['friendRequests'] ?? []);

        if (requestIds.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: requestIds.length,
          itemBuilder: (context, index) {
            return _FriendRequestTile(
              requestId: requestIds[index],
              onAccept: onAccept,
              onReject: onReject,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Нет новых запросов',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  final String requestId;
  final Function(String) onAccept;
  final Function(String) onReject;

  const _FriendRequestTile({
    required this.requestId,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(requestId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return ListTile(title: Text('Загрузка...'));
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: _buildAvatar(data?['photoURL']),
            title: Text(data?['displayName'] ?? 'Unknown'),
            subtitle: Text('Хочет добавить вас в друзья'),
            trailing: _buildActions(),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? photoURL) {
    return CircleAvatar(
      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
      child: photoURL == null ? Icon(Icons.person) : null,
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.check, color: Colors.green),
          onPressed: () => onAccept(requestId),
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.red),
          onPressed: () => onReject(requestId),
        ),
      ],
    );
  }
}
