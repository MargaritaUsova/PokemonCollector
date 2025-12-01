import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../viewmodels/account_viewmodel.dart';
import 'friend_detail_screen.dart';

class IncomingRequestsTab extends StatelessWidget {
  final String userId;
  final AccountViewModel viewModel;

  const IncomingRequestsTab({
    required this.userId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<String>>(
      stream: viewModel.getFriendRequests(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final requestIds = snapshot.data!;

        if (requestIds.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: requestIds.length,
          itemBuilder: (context, index) {
            return _IncomingRequestTile(
              requestId: requestIds[index],
              userId: userId,
              viewModel: viewModel,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: theme.colorScheme.outline),
          SizedBox(height: 16),
          Text(
            'Нет новых запросов',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  final String requestId;
  final String userId;
  final AccountViewModel viewModel;

  const _IncomingRequestTile({
    required this.requestId,
    required this.userId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(requestId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircularProgressIndicator(strokeWidth: 2),
              title: Text('Загрузка...'),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendDetailScreen(
                  friendId: requestId,
                  friendName: data?['displayName'] ?? 'Unknown',
                  isIncomingRequest: true,
                  currentUserId: userId,
                  viewModel: viewModel,
                ),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 2,
            child: ListTile(
              leading: _buildAvatar(data?['photoURL'], theme),
              title: Text(
                data?['displayName'] ?? 'Unknown',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Хочет добавить вас в друзья'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Принять',
                    onPressed: () => viewModel.acceptFriendRequest(userId, requestId),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Отклонить',
                    onPressed: () => viewModel.rejectFriendRequest(userId, requestId),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? photoURL, ThemeData theme) {
    return CircleAvatar(
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
      child: photoURL == null ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer) : null,
    );
  }
}
