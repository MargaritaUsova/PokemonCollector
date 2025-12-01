import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/viewModels/auth_view_model.dart';
import '../../../../main.dart';

class AccountAppBar extends StatelessWidget {
  final User? currentUser;

  const AccountAppBar({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  colors: isDark
                      ? [Color(0xFF2C2C2C), Color(0xFF1E1E1E), Color(0xFF121212)]
                      : [Color(0xFFFFD56F), Color(0xFFFFF3B0), Colors.amber.shade200],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _buildAvatar(currentUser, theme),
                  SizedBox(height: 12),
                  Text(
                    currentUser?.displayName ?? 'Пользователь',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      shadows: [
                        Shadow(
                          color: isDark ? Colors.black45 : Colors.white.withOpacity(0.5),
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(theme.brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode),
          tooltip: 'Сменить тему',
          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
        ),
        IconButton(
          icon: Icon(Icons.logout),
          tooltip: 'Выйти',
          onPressed: () {
            authVM.signOut();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildAvatar(User? currentUser, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary, width: 4),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: theme.colorScheme.surfaceVariant,
        backgroundImage: currentUser?.photoURL != null ? NetworkImage(currentUser!.photoURL!) : null,
        child: currentUser?.photoURL == null
            ? Icon(Icons.person, size: 50, color: theme.colorScheme.onSurfaceVariant)
            : null,
      ),
    );
  }
}
