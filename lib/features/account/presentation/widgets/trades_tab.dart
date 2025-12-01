import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trade_detail_screen.dart';

class TradesTab extends StatefulWidget {
  final String userId;

  const TradesTab({required this.userId});

  @override
  State<TradesTab> createState() => _TradesTabState();
}

class _TradesTabState extends State<TradesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          labelStyle: TextStyle(fontSize: 12),
          tabs: [
            Tab(text: 'Все'),
            Tab(text: 'Входящие'),
            Tab(text: 'История'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AllPendingTradesTab(userId: widget.userId),
              _IncomingTradesTab(userId: widget.userId),
              _TradeHistoryTab(userId: widget.userId),
            ],
          ),
        ),
      ],
    );
  }
}

class _AllPendingTradesTab extends StatelessWidget {
  final String userId;

  const _AllPendingTradesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('status', isEqualTo: 'pending')
          .where('to', isEqualTo: userId)
          .snapshots(),
      builder: (context, incomingSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tradeRequests')
              .where('status', isEqualTo: 'pending')
              .where('from', isEqualTo: userId)
              .snapshots(),
          builder: (context, outgoingSnapshot) {
            if (!incomingSnapshot.hasData || !outgoingSnapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }

            final allTrades = <DocumentSnapshot>[
              ...incomingSnapshot.data!.docs,
              ...outgoingSnapshot.data!.docs,
            ];

            allTrades.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bTime.compareTo(aTime);
            });

            if (allTrades.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz_outlined, size: 80, color: theme.colorScheme.outline),
                    SizedBox(height: 16),
                    Text(
                      'Нет активных обменов',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: allTrades.length,
              itemBuilder: (context, index) {
                final tradeDoc = allTrades[index];
                final data = tradeDoc.data() as Map<String, dynamic>;
                final isIncoming = data['to'] == userId;

                return _CompactTradeTile(
                  tradeId: tradeDoc.id,
                  fromUserId: data['from'],
                  toUserId: data['to'],
                  fromCard: data['fromCard'].toString(),
                  toCard: data['toCard'].toString(),
                  isIncoming: isIncoming,
                  currentUserId: userId,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _IncomingTradesTab extends StatelessWidget {
  final String userId;

  const _IncomingTradesTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('status', isEqualTo: 'pending')
          .where('to', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
        }

        final trades = snapshot.data!.docs;

        if (trades.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: theme.colorScheme.outline),
                SizedBox(height: 16),
                Text(
                  'Нет входящих предложений',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: trades.length,
          itemBuilder: (context, index) {
            final tradeDoc = trades[index];
            final data = tradeDoc.data() as Map<String, dynamic>;

            return _CompactTradeTile(
              tradeId: tradeDoc.id,
              fromUserId: data['from'],
              toUserId: data['to'],
              fromCard: data['fromCard'].toString(),
              toCard: data['toCard'].toString(),
              isIncoming: true,
              currentUserId: userId,
            );
          },
        );
      },
    );
  }
}

class _TradeHistoryTab extends StatelessWidget {
  final String userId;

  const _TradeHistoryTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tradeRequests')
          .where('from', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .limit(50)
          .snapshots(),
      builder: (context, fromSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tradeRequests')
              .where('to', isEqualTo: userId)
              .where('status', isEqualTo: 'completed')
              .limit(50)
              .snapshots(),
          builder: (context, toSnapshot) {
            if (!fromSnapshot.hasData || !toSnapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }

            final allTrades = <DocumentSnapshot>[
              ...fromSnapshot.data!.docs,
              ...toSnapshot.data!.docs,
            ];

            allTrades.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
              final bTime = (bData['timestamp'] as Timestamp?)?.toDate() ?? DateTime(0);
              return bTime.compareTo(aTime);
            });

            if (allTrades.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 80, color: theme.colorScheme.outline),
                    SizedBox(height: 16),
                    Text(
                      'История обменов пуста',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: allTrades.length,
              itemBuilder: (context, index) {
                final tradeDoc = allTrades[index];
                final data = tradeDoc.data() as Map<String, dynamic>;
                final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                return _HistoryTradeTile(
                  tradeId: tradeDoc.id,
                  fromUserId: data['from'],
                  toUserId: data['to'],
                  fromCard: data['fromCard'].toString(),
                  toCard: data['toCard'].toString(),
                  timestamp: timestamp,
                  currentUserId: userId,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CompactTradeTile extends StatelessWidget {
  final String tradeId;
  final String fromUserId;
  final String toUserId;
  final String fromCard;
  final String toCard;
  final bool isIncoming;
  final String currentUserId;

  const _CompactTradeTile({
    required this.tradeId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromCard,
    required this.toCard,
    required this.isIncoming,
    required this.currentUserId,
  });

  Future<void> _acceptTrade(BuildContext context) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(FirebaseFirestore.instance.collection('users').doc(currentUserId), {
        'pokemons': FieldValue.arrayRemove([toCard])
      });
      batch.update(FirebaseFirestore.instance.collection('users').doc(currentUserId), {
        'pokemons': FieldValue.arrayUnion([fromCard])
      });

      batch.update(FirebaseFirestore.instance.collection('users').doc(fromUserId), {
        'pokemons': FieldValue.arrayRemove([fromCard])
      });
      batch.update(FirebaseFirestore.instance.collection('users').doc(fromUserId), {
        'pokemons': FieldValue.arrayUnion([toCard])
      });

      batch.update(FirebaseFirestore.instance.collection('tradeRequests').doc(tradeId), {
        'status': 'completed',
        'timestamp': Timestamp.now(),
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Обмен завершен!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print('Error accepting trade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectTrade() async {
    await FirebaseFirestore.instance.collection('tradeRequests').doc(tradeId).update({
      'status': 'rejected',
    });
  }

  Future<void> _cancelTrade() async {
    await FirebaseFirestore.instance.collection('tradeRequests').doc(tradeId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUserId = isIncoming ? fromUserId : toUserId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['displayName'] ?? 'Unknown';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TradeDetailScreen(
                  tradeId: tradeId,
                  fromUserId: fromUserId,
                  toUserId: toUserId,
                  fromCard: fromCard,
                  toCard: toCard,
                  timestamp: null,
                  currentUserId: currentUserId,
                ),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Icon(
                isIncoming ? Icons.call_received : Icons.call_made,
                color: isIncoming ? Colors.green : Colors.blue,
              ),
              title: Text(
                isIncoming ? 'От: $userName' : 'Кому: $userName',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                isIncoming ? 'Предлагает обмен' : 'Ждет ответа',
                style: TextStyle(fontSize: 12),
              ),
              trailing: isIncoming
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green, size: 20),
                    onPressed: () => _acceptTrade(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: _rejectTrade,
                  ),
                ],
              )
                  : IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _cancelTrade,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTradeTile extends StatelessWidget {
  final String tradeId;
  final String fromUserId;
  final String toUserId;
  final String fromCard;
  final String toCard;
  final DateTime? timestamp;
  final String currentUserId;

  const _HistoryTradeTile({
    required this.tradeId,
    required this.fromUserId,
    required this.toUserId,
    required this.fromCard,
    required this.toCard,
    required this.timestamp,
    required this.currentUserId,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Сегодня';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUserId = fromUserId == currentUserId ? toUserId : fromUserId;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['displayName'] ?? 'Unknown';

        return Card(
          margin: EdgeInsets.symmetric(vertical: 4),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              'Обмен с $userName',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            subtitle: Text(
              _formatDate(timestamp),
              style: TextStyle(fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TradeDetailScreen(
                    tradeId: tradeId,
                    fromUserId: fromUserId,
                    toUserId: toUserId,
                    fromCard: fromCard,
                    toCard: toCard,
                    timestamp: timestamp,
                    currentUserId: currentUserId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
