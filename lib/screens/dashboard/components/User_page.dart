import 'package:admin/controllers/User_controller.dart';
import 'package:admin/models/User.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class UserPage extends StatelessWidget {
  const UserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());
    return Obx(() {
      if (userController.isLoading.value) {
        return const Scaffold(
          backgroundColor: Color(0xFF0F0F0F),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading users...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: _buildAppBar(userController),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStatsSection(userController),
                const SizedBox(height: 32),
                _buildUsersTable(userController, context),
              ],
            ),
          ),
        );
      }
    });
  }

  PreferredSizeWidget _buildAppBar(UserController userController) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'User Management',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        // MODIFIED: Replaced IconButton with TextButton.icon
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextButton.icon(
            onPressed: () => userController.fetchUsers(),
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white70),
            label: const Text(
              'Refresh',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // MODIFIED: Replaced icon-only PopupMenuButton with a labeled child
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') {
                userController.exportToPdf(userController.filteredUsers);
              } else if (value == 'excel') {
                userController.exportToExcel();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pdf',
                child: Text('Export to PDF'),
              ),
              const PopupMenuItem<String>(
                value: 'excel',
                child: Text('Export to Excel'),
              ),
            ],
            // MODIFIED: Using a custom child for the button
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.download_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Export',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor and manage user registrations',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white60,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(UserController userController) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'User Statistics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth < 600
                  ? 2
                  : constraints.maxWidth < 1100
                      ? 4
                      : 7;
              double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
              double childAspectRatio = itemWidth / 175;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCard(
                    'Total Users',
                    userController.users.length.toString(),
                    Icons.people_rounded,
                    const Color(0xFF8B5CF6),
                  ),
                  _buildStatCard(
                    'Active Subscriptions',
                    userController.activeSubCount.value.toString(),
                    Icons.check_circle_rounded,
                    const Color(0xFF10B981),
                  ),
                  _buildStatCard(
                    'Expired Subscriptions',
                    userController.expiredSubCount.value.toString(),
                    Icons.cancel_rounded,
                    const Color(0xFFEF4444),
                  ),
                  _buildStatCard(
                    'No Subscription',
                    userController.noSubCount.value.toString(),
                    Icons.no_accounts_rounded,
                    const Color(0xFF6B7280),
                  ),
                  _buildStatCard(
                    'TV Users',
                    userController.tvUserCount.value.toString(),
                    Icons.tv_rounded,
                    const Color(0xFFEC4899),
                  ),
                  _buildStatCard(
                    'Last 24 Hours',
                    userController.last24HoursUsersCount.value.toString(),
                    Icons.hourglass_bottom_rounded,
                    const Color(0xFFF59E0B),
                  ),
                  _buildStatCard(
                    'Last 7 Days',
                    userController.last7DaysUsersCount.value.toString(),
                    Icons.date_range_rounded,
                    const Color(0xFF3B82F6),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(UserController userController, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.people_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'User Directory',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Obx(() {
                  final label = userController.activeFilterLabel.value;
                  final isFiltered = label != 'All Users';
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'all') {
                        userController.clearFilter();
                      } else if (value == 'last24') {
                        userController.filterLast24Hours();
                      } else if (value == 'active_sub') {
                        userController.filterActiveSubUsers();
                      } else if (value == 'expired_sub') {
                        userController.filterExpiredSubUsers();
                      } else if (value == 'no_sub') {
                        userController.filterNoSubUsers();
                      } else if (value == 'tv_users') {
                        userController.filterTvUsers();
                      }
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    color: const Color(0xFF1A1A1A),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      _filterMenuItem(
                        value: 'all',
                        label: 'All Users',
                        icon: Icons.people_rounded,
                        color: Colors.white70,
                        active: label == 'All Users',
                      ),
                      const PopupMenuDivider(height: 1),
                      _filterMenuItem(
                        value: 'active_sub',
                        label: 'Active Subscriptions',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        active: label == 'Active Subscriptions',
                      ),
                      _filterMenuItem(
                        value: 'expired_sub',
                        label: 'Expired Subscriptions',
                        icon: Icons.cancel_rounded,
                        color: const Color(0xFFEF4444),
                        active: label == 'Expired Subscriptions',
                      ),
                      _filterMenuItem(
                        value: 'no_sub',
                        label: 'No Subscriptions',
                        icon: Icons.no_accounts_rounded,
                        color: const Color(0xFF6B7280),
                        active: label == 'No Subscriptions',
                      ),
                      const PopupMenuDivider(height: 1),
                      _filterMenuItem(
                        value: 'last24',
                        label: 'Last 24 Hours',
                        icon: Icons.hourglass_bottom_rounded,
                        color: const Color(0xFFF59E0B),
                        active: label == 'Last 24 Hours',
                      ),
                      _filterMenuItem(
                        value: 'tv_users',
                        label: 'TV Users',
                        icon: Icons.tv_rounded,
                        color: const Color(0xFFEC4899),
                        active: label == 'TV Users',
                      ),
                    ],
                    tooltip: 'Filter Users',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFiltered
                            ? const Color(0xFF6366F1).withOpacity(0.15)
                            : const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFiltered
                              ? const Color(0xFF6366F1).withOpacity(0.5)
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list_rounded,
                              color: isFiltered
                                  ? const Color(0xFF6366F1)
                                  : Colors.white70,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              color: isFiltered
                                  ? const Color(0xFF6366F1)
                                  : Colors.white70,
                              fontWeight: isFiltered
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (isFiltered) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: userController.clearFilter,
                              child: const Icon(Icons.close_rounded,
                                  size: 14,
                                  color: Color(0xFF6366F1)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 16),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        '${userController.filteredUsers.length} users',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
              ],
            ),
          ),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Obx(() => TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: userController.searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or phone...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.white38),
                    suffixIcon: userController.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white38, size: 20),
                            onPressed: () => userController.searchUsers(''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6366F1), width: 2),
                    ),
                  ),
                )),
          ),

          // ── Table ──
          SizedBox(
            width: double.infinity,
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(color: Colors.white),
                textTheme: Theme.of(context).textTheme.copyWith(
                      bodySmall: const TextStyle(color: Colors.white),
                    ),
              ),
              child: Obx(() {
                final key = ValueKey(
                    '${userController.rowsPerPage.value}_'
                    '${userController.filteredUsers.length}_'
                    '${userController.searchQuery.value}');
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: PaginatedDataTable(
                    key: key,
                    headingRowColor: MaterialStateProperty.all(
                        const Color(0xFF0F0F0F)),
                    horizontalMargin: 0,
                    columnSpacing: 20,
                    rowsPerPage: userController.rowsPerPage.value,
                    availableRowsPerPage: const [5, 10, 20, 50],
                    onRowsPerPageChanged: (value) {
                      userController.rowsPerPage.value = value!;
                    },
                    columns: [
                      DataColumn(
                        label: Expanded(
                            child: Text('Name',
                                style: _headerTextStyle())),
                      ),
                      DataColumn(
                        label:
                            Text('Phone', style: _headerTextStyle()),
                      ),
                      DataColumn(
                        label: Text('Registered',
                            style: _headerTextStyle()),
                      ),
                      DataColumn(
                        label: Text('Subscription',
                            style: _headerTextStyle()),
                      ),
                      DataColumn(
                        label: Text('Expiry',
                            style: _headerTextStyle()),
                      ),
                      DataColumn(
                        label: Text('Actions',
                            style: _headerTextStyle()),
                      ),
                    ],
                    source: _UserDataSource(
                      userController: userController,
                      context: context,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Colors.white,
      letterSpacing: -0.2,
    );
  }

  static PopupMenuItem<String> _filterMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: active ? color : Colors.white,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
          if (active)
            Icon(Icons.check_rounded, color: color, size: 16),
        ],
      ),
    );
  }
}

class _UserDataSource extends DataTableSource {
  final UserController userController;
  final BuildContext context;

  _UserDataSource({required this.userController, required this.context});

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  DataRow getRow(int index) {
    if (index >= userController.filteredUsers.length) {
      return DataRow(cells: List.filled(6, const DataCell(Text(''))));
    }
    final user = userController.filteredUsers[index];

    final isActive = user.active == true;
    final hasExpiry = user.subscriptionExpiryDate != null;
    final daysLeft = hasExpiry
        ? user.subscriptionExpiryDate!.difference(DateTime.now()).inDays
        : 0;
    final isExpired = hasExpiry && daysLeft < 0;

    return DataRow(cells: [
      // ── Name + Email ──
      DataCell(Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              (user.name?.isNotEmpty == true)
                  ? user.name![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.name ?? 'N/A',
                  style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text(user.email ?? 'No email',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45),
                      fontWeight: FontWeight.w400),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ])),

      // ── Phone ──
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(user.phone ?? 'N/A',
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500)),
      )),

      // ── Registration date ──
      DataCell(Text(
        user.registrationDate != null
            ? _dateFmt.format(user.registrationDate!)
            : 'N/A',
        style: const TextStyle(fontSize: 13, color: Colors.white60),
      )),

      // ── Subscription status badge ──
      DataCell(_buildSubBadge(isActive, isExpired)),

      // ── Expiry ──
      DataCell(hasExpiry
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_dateFmt.format(user.subscriptionExpiryDate!),
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            isExpired ? Colors.red[300] : Colors.white60)),
                if (!isExpired)
                  Text('$daysLeft days left',
                      style: TextStyle(
                          fontSize: 11,
                          color: daysLeft <= 7
                              ? Colors.orange[300]
                              : Colors.white38)),
              ],
            )
          : const Text('No subscription',
              style: TextStyle(fontSize: 13, color: Colors.white38))),

      // ── Actions ──
      DataCell(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: () =>
                _showEditUserDialog(context, userController, user),
            icon: const Icon(Icons.edit_rounded,
                color: Color(0xFF3B82F6), size: 18),
            label: const Text('Edit',
                style: TextStyle(color: Color(0xFF3B82F6))),
            style: TextButton.styleFrom(
              backgroundColor:
                  const Color(0xFF3B82F6).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () =>
                _showDeleteDialog(context, userController, user),
            icon: const Icon(Icons.delete_rounded,
                color: Color(0xFFEF4444), size: 18),
            label: const Text('Delete',
                style: TextStyle(color: Color(0xFFEF4444))),
            style: TextButton.styleFrom(
              backgroundColor:
                  const Color(0xFFEF4444).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
            ),
          ),
        ],
      )),
    ]);
  }

  Widget _buildSubBadge(bool isActive, bool isExpired) {
    Color bg;
    Color fg;
    String label;
    if (isActive && !isExpired) {
      bg = const Color(0xFF10B981).withOpacity(0.15);
      fg = const Color(0xFF10B981);
      label = 'Active';
    } else if (isExpired) {
      bg = const Color(0xFFEF4444).withOpacity(0.15);
      fg = const Color(0xFFEF4444);
      label = 'Expired';
    } else {
      bg = Colors.white.withOpacity(0.06);
      fg = Colors.white38;
      label = 'Inactive';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => userController.filteredUsers.length;

  @override
  int get selectedRowCount => 0;

  void _showDeleteDialog(
      BuildContext context, UserController userController, User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 28),
              SizedBox(width: 12),
              Text(
                'Delete User',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                userController.deleteUser(user.id!);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(
      BuildContext context, UserController userController, User user) {
    userController.emailController.text = user.email ?? '';
    userController.nameController.text = user.name ?? '';
    userController.phoneController.text = user.phone ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 28),
              SizedBox(width: 12),
              Text(
                'Edit User',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: userController.nameController,
                  label: 'Full Name',
                  icon: Icons.person_rounded,
                ),
                _buildTextField(
                  controller: userController.emailController,
                  label: 'Email Address',
                  icon: Icons.email_rounded,
                ),
                _buildTextField(
                  controller: userController.phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_rounded,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                User updatedUser = User(
                  id: user.id,
                  email: userController.emailController.text,
                  name: userController.nameController.text,
                  phone: userController.phoneController.text,
                );
                userController.updateUser(user.id!, updatedUser);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          filled: true,
          fillColor: const Color(0xFF0F0F0F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
      ),
    );
  }
}