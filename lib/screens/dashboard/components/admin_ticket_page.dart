import 'package:admin/screens/dashboard/components/admin_chat_page.dart'; // Ensure this path is correct for your project
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminTicketPage extends StatefulWidget {
  const AdminTicketPage({Key? key}) : super(key: key);

  @override
  State<AdminTicketPage> createState() => _AdminTicketPageState();
}

class _AdminTicketPageState extends State<AdminTicketPage> {
  final List<String> _statusOptions = const ['open', 'in-progress', 'closed'];
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateTicketStatus(String ticketId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to "$newStatus"'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _showChatWindow(BuildContext context, String ticketId, String subject) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardColor,
          ),
          child: AdminChatWindow(
            ticketId: ticketId,
            ticketSubject: subject,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterTickets(
      List<QueryDocumentSnapshot> tickets) {
    var filtered = tickets;

    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((ticket) {
        final data = ticket.data() as Map<String, dynamic>;
        return (data['status'] ?? '').toLowerCase() == _selectedFilter;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ticket) {
        final data = ticket.data() as Map<String, dynamic>;
        final subject = (data['subject'] ?? '').toLowerCase();
        final name = (data['name'] ?? '').toLowerCase();
        final category = (data['category'] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return subject.contains(query) ||
            name.contains(query) ||
            category.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.support_agent,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  "Support Tickets Management",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filters and Search
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list, size: 20),
                      items: [
                        const DropdownMenuItem(
                            value: 'all', child: Text('All Tickets')),
                        ..._statusOptions.map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.toUpperCase()),
                            )),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFilter = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Search Field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search tickets by subject, user, or category...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tickets')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error}",
                            style: TextStyle(color: Colors.red)),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No support tickets found."),
                      );
                    }

                    final allTickets = snapshot.data!.docs;
                    final filteredTickets = _filterTickets(allTickets);

                    return Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Found ${filteredTickets.length} ticket${filteredTickets.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SizedBox(
                                  width: constraints.maxWidth,
                                  child: DataTable(
                                    horizontalMargin: 16,
                                    columnSpacing: 24,
                                    headingRowHeight: 56,
                                    dataRowMinHeight: 64,
                                    dataRowMaxHeight: 72,
                                    headingRowColor: MaterialStateProperty.all(
                                      isDark
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade100,
                                    ),
                                    columns: const [
                                      DataColumn(
                                          label: Text('SUBJECT',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('USER',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('CATEGORY',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('CREATED',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('STATUS',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      DataColumn(
                                          label: Text('ACTIONS',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                    ],
                                    rows: filteredTickets.map((ticket) {
                                      final data =
                                          ticket.data() as Map<String, dynamic>;
                                      final subject = data['subject'] ?? 'N/A';
                                      final status =
                                          data['status'] ?? 'unknown';
                                      final userId = data['userId'] as String?;
                                      final category =
                                          data['category'] ?? 'N/A';

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Container(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 200),
                                              child: Text(subject,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                            ),
                                          ),
                                          // --- THIS IS THE MODIFIED CELL ---
                                          DataCell(
                                            userId != null && userId.isNotEmpty
                                                ? UserInfoCell(userId: userId)
                                                : Text('Unknown User',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: Colors
                                                            .grey.shade600)),
                                          ),
                                          // --- END OF MODIFICATION ---
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              child: Text(category,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                            ),
                                          ),
                                          DataCell(Text(_formatTimestamp(
                                              data['createdAt']))),
                                          DataCell(_buildStatusChip(status)),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.chat_bubble_outline,
                                                      size: 20),
                                                  onPressed: () =>
                                                      _showChatWindow(context,
                                                          ticket.id, subject),
                                                  tooltip: 'Open Chat',
                                                  style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.blue.shade50,
                                                      foregroundColor:
                                                          Colors.blue.shade600),
                                                ),
                                                const SizedBox(width: 8),
                                                _buildActionMenu(
                                                    ticket.id, status),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionMenu(String ticketId, String currentStatus) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (newStatus) => _updateTicketStatus(ticketId, newStatus),
      itemBuilder: (BuildContext context) {
        return _statusOptions.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(choice),
                  size: 16,
                  color: currentStatus == choice
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  choice.toUpperCase(),
                  style: TextStyle(
                    fontWeight: currentStatus == choice
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: currentStatus == choice
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.fiber_new;
      case 'in-progress':
        return Icons.hourglass_empty;
      case 'closed':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.green.shade600;
        icon = Icons.fiber_new;
        break;
      case 'in-progress':
        color = Colors.orange.shade600;
        icon = Icons.hourglass_empty;
        break;
      case 'closed':
        color = Colors.blueGrey.shade500;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey.shade600;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11)),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate().toLocal();

    return DateFormat("MMMM d, yyyy 'at' h:mm a").format(date);
  }
}

class UserInfoCell extends StatefulWidget {
  final String userId;
  const UserInfoCell({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserInfoCell> createState() => _UserInfoCellState();
}

class _UserInfoCellState extends State<UserInfoCell> {
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future once to prevent re-fetching on every rebuild
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {
        // --- State: Loading ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade200),
              const SizedBox(width: 8),
              Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4))),
            ],
          );
        }

        // --- State: Error or User Not Found ---
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Row(
            children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.red.shade100,
                  child: const Icon(Icons.person_off,
                      size: 16, color: Colors.red)),
              const SizedBox(width: 8),
              Text('User Not Found',
                  style: TextStyle(
                      color: Colors.red.shade400, fontStyle: FontStyle.italic),
                  overflow: TextOverflow.ellipsis),
            ],
          );
        }

        // --- State: Success ---
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        // *** This is where we get the name from the 'users' collection data ***
        final userName = userData['name'] as String? ?? 'Unnamed User';

        return Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(userName, overflow: TextOverflow.ellipsis)),
          ],
        );
      },
    );
  }
}
