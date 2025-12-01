import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../friendCollection/data/presentation/screens/friend_collection_screen.dart';
import '../viewmodels/account_viewmodel.dart';

class FriendsTab extends StatelessWidget {
  final String userId;

  const FriendsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.read<AccountViewModel>();

    return StreamBuilder<List<String>>(
      stream: viewModel.getFriendsList(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final friendIds = snapshot.data!;

        if (friendIds.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 8),
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            return _FriendTile(
              friendId: friendIds[index],
              currentUserId: userId,
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
          Icon(Icons.people_outline, size: 80, color: theme.colorScheme.outline),
          SizedBox(height: 16),
          Text(
            'У вас пока нет друзей',
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

class _FriendTile extends StatelessWidget {
  final String friendId;
  final String currentUserId;
  final AccountViewModel viewModel;

  const _FriendTile({
    required this.friendId,
    required this.currentUserId,
    required this.viewModel,
  });

  Future<void> _confirmRemoveFriend(BuildContext context, String friendName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.person_remove, size: 48, color: Colors.orange),
        title: Text('Удалить из друзей?'),
        content: Text('Вы уверены, что хотите удалить $friendName из друзей?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      viewModel.removeFriend(currentUserId, friendId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
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
        final friendName = data?['displayName'] ?? 'Unknown';

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 2,
          child: ListTile(
            leading: _buildAvatar(data?['photoURL'], theme),
            title: Text(
              friendName,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(data?['email'] ?? ''),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FriendCollectionScreen(
                        friendId: friendId,
                        friendName: friendName,
                      ),
                    ),
                  );
                } else if (value == 'remove') {
                  _confirmRemoveFriend(context, friendName);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.collections, size: 20),
                      SizedBox(width: 12),
                      Text('Смотреть коллекцию'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Удалить из друзей', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FriendCollectionScreen(
                  friendId: friendId,
                  friendName: friendName,
                ),
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
