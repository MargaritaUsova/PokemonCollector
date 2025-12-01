import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/account_viewmodel.dart';
import '../widgets/account_app_bar.dart';
import '../widgets/search_section.dart';
import '../widgets/friends_tab.dart';
import '../widgets/incoming_requests_tab.dart';
import '../widgets/outgoing_requests_tab.dart';
import '../widgets/trades_tab.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final viewModel = context.watch<AccountViewModel>();
    final theme = Theme.of(context);

    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage(viewModel.errorMessage!, isSuccess: false);
        viewModel.clearMessages();
      });
    }
    if (viewModel.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage(viewModel.successMessage!, isSuccess: true);
        viewModel.clearMessages();
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AccountAppBar(currentUser: currentUser),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SearchSection(
                  controller: _searchController,
                  viewModel: viewModel,
                  currentUserId: currentUser?.uid ?? '',
                ),
                if (_searchController.text.isEmpty)
                  _buildTabsSection(currentUser?.uid ?? '', theme, viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsSection(String userId, ThemeData theme, AccountViewModel viewModel) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.people), text: 'Друзья'),
            Tab(icon: Icon(Icons.inbox), text: 'Входящие'),
            Tab(icon: Icon(Icons.send), text: 'Исходящие'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Обмены'),
          ],
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              FriendsTab(userId: userId),
              IncomingRequestsTab(userId: userId, viewModel: viewModel),
              OutgoingRequestsTab(userId: userId, viewModel: viewModel),
              TradesTab(userId: userId),
            ],
          ),
        ),
      ],
    );
  }
}
