import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../viewmodels/account_viewmodel.dart';

class FriendDetailScreen extends StatelessWidget {
  final String friendId;
  final String friendName;
  final bool isIncomingRequest;
  final String currentUserId;
  final AccountViewModel viewModel;

  const FriendDetailScreen({
    required this.friendId,
    required this.friendName,
    required this.isIncomingRequest,
    required this.currentUserId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person, size: 24),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                isIncomingRequest ? 'Входящий запрос' : 'Исходящий запрос',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(friendId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: theme.colorScheme.primary),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final photoURL = data?['photoURL'];
          final displayName = data?['displayName'] ?? 'Unknown';
          final email = data?['email'] ?? 'Неизвестно';
          final pokemons = (data?['pokemons'] as List?)?.length ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Профиль
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: theme.brightness == Brightness.dark
                          ? [Color(0xFF1E3A2F), Color(0xFF2D5F2D)]
                          : [Color(0xFFB0FFB0), Color(0xFF6FFF6F)],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage:
                        photoURL != null ? NetworkImage(photoURL) : null,
                        child: photoURL == null
                            ? Icon(Icons.person, size: 50)
                            : null,
                      ),
                      SizedBox(height: 16),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Информация
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildInfoTile(
                        icon: Icons.catching_pokemon,
                        label: 'Карточек в коллекции',
                        value: '$pokemons',
                        theme: theme,
                      ),
                      SizedBox(height: 8),
                      _buildInfoTile(
                        icon: Icons.calendar_today,
                        label: 'Статус запроса',
                        value: isIncomingRequest
                            ? 'Входящий запрос'
                            : 'Исходящий запрос',
                        theme: theme,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Кнопки действия
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: isIncomingRequest
                      ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            viewModel.acceptFriendRequest(
                              currentUserId,
                              friendId,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.check_circle),
                          label: Text('Принять'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            viewModel.rejectFriendRequest(
                              currentUserId,
                              friendId,
                            );
                            Navigator.pop(context);
                          },
                          icon: Icon(Icons.cancel),
                          label: Text('Отклонить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                      : ElevatedButton.icon(
                    onPressed: () {
                      viewModel.cancelFriendRequest(
                        currentUserId,
                        friendId,
                      );
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.close),
                    label: Text('Отменить запрос'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
