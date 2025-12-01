import 'package:flutter/material.dart';
import '../viewmodels/account_viewmodel.dart';

class SearchSection extends StatelessWidget {
  final TextEditingController controller;
  final AccountViewModel viewModel;
  final String currentUserId;

  const SearchSection({
    required this.controller,
    required this.viewModel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Поиск пользователей...',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  viewModel.searchUsers('', currentUserId);
                },
              )
                  : null,
            ),
            onChanged: (query) => viewModel.searchUsers(query, currentUserId),
          ),
        ),
        if (viewModel.isSearching)
          Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          )
        else if (viewModel.searchResults.isNotEmpty)
          _SearchResultsList(
            results: viewModel.searchResults,
            viewModel: viewModel,
            currentUserId: currentUserId,
          )
        else if (controller.text.isNotEmpty)
            _buildEmptyState(theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          SizedBox(height: 8),
          Text(
            'Пользователи не найдены',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final AccountViewModel viewModel;
  final String currentUserId;

  const _SearchResultsList({
    required this.results,
    required this.viewModel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final user = results[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _buildAvatar(user['photoURL'], theme),
            title: Text(user['displayName'], style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(user['email']),
            trailing: IconButton(
              icon: Icon(Icons.person_add),
              color: theme.colorScheme.primary,
              onPressed: () => viewModel.sendFriendRequest(currentUserId, user['uid']),
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
