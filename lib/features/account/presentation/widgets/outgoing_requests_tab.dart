import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/account_viewmodel.dart';
import 'friend_detail_screen.dart';

class OutgoingRequestsTab extends StatelessWidget {
  final String userId;
  final AccountViewModel viewModel;

  const OutgoingRequestsTab({
    required this.userId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: viewModel.getOutgoingRequests(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final requests = snapshot.data!;

        if (requests.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final user = requests[index];
            return _OutgoingRequestTile(
              userId: userId,
              targetUserId: user['uid'],
              userName: user['displayName'],
              userEmail: user['email'],
              photoURL: user['photoURL'],
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
          Icon(Icons.send_outlined, size: 80, color: theme.colorScheme.outline),
          SizedBox(height: 16),
          Text(
            'Нет исходящих запросов',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Отправленные запросы появятся здесь',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  final String userId;
  final String targetUserId;
  final String userName;
  final String userEmail;
  final String? photoURL;
  final AccountViewModel viewModel;

  const _OutgoingRequestTile({
    required this.userId,
    required this.targetUserId,
    required this.userName,
    required this.userEmail,
    this.photoURL,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FriendDetailScreen(
              friendId: targetUserId,
              friendName: userName,
              isIncomingRequest: false,
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
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
            child: photoURL == null ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer) : null,
          ),
          title: Text(
            userName,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Ожидает ответа'),
          trailing: IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            tooltip: 'Отменить запрос',
            onPressed: () => viewModel.cancelFriendRequest(userId, targetUserId),
          ),
        ),
      ),
    );
  }
}
