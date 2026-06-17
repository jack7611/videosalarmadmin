import 'package:admin/controllers/admin_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminSignInController());
    final screenWidth = MediaQuery.of(context).size.width;

    // Web-specific breakpoints
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
              Color(0xFF2A2A2A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : (isTablet ? 24 : 16),
          ),
          child: Row(
            children: [
              _buildLogo(context),
              if (isDesktop) ...[
                const SizedBox(width: 48),
                Expanded(child: _buildDesktopNavigation(context)),
              ] else if (isTablet) ...[
                const SizedBox(width: 32),
                Expanded(child: _buildTabletNavigation(context)),
              ] else ...[
                const Spacer(),
              ],
              _buildRightSection(
                  context, controller, isDesktop, isTablet, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/Dashboard'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/images/logo.png",
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              const Text(
                "Admin Panel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopNavigation(BuildContext context) {
    final menuItems = _getMenuItems();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...menuItems.take(5).map((item) =>
            _buildNavButton(context, item, showLabel: true, isCompact: false)),

        // More dropdown for remaining items
        if (menuItems.length > 5)
          _buildMoreDropdown(context, menuItems.skip(5).toList()),
      ],
    );
  }

  Widget _buildTabletNavigation(BuildContext context) {
    final menuItems = _getMenuItems();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...menuItems.take(3).map((item) => _buildNavButton(context, item,
              showLabel: false, isCompact: true)),
          if (menuItems.length > 3)
            _buildMoreDropdown(context, menuItems.skip(3).toList()),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    _MenuItem item, {
    required bool showLabel,
    required bool isCompact,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isActive = currentRoute == item.route;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 4 : 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, item.route),
              hoverColor: Colors.white.withOpacity(0.08),
              splashColor: Colors.blue.withOpacity(0.2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.2),
                            Colors.blue.withOpacity(0.1),
                          ],
                        )
                      : null,
                  border: isActive
                      ? Border.all(
                          color: Colors.blue.withOpacity(0.4),
                          width: 1,
                        )
                      : Border.all(
                          color: Colors.transparent,
                          width: 1,
                        ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      item.iconPath,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isActive ? Colors.blue : Colors.white70,
                        BlendMode.srcIn,
                      ),
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 12),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isActive ? Colors.blue : Colors.white70,
                          fontSize: 15,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreDropdown(BuildContext context, List<_MenuItem> items) {
    return PopupMenuButton<_MenuItem>(
      offset: const Offset(0, 60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1A1A),
      elevation: 20,
      shadowColor: Colors.black.withOpacity(0.5),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "More",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => items
          .map((item) => PopupMenuItem<_MenuItem>(
                value: item,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        item.iconPath,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                            Colors.white70, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
      onSelected: (item) => Navigator.pushNamed(context, item.route),
    );
  }

  Widget _buildRightSection(
    BuildContext context,
    AdminSignInController controller,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobile) ...[
          _buildNotificationButton(context),
          const SizedBox(width: 16),
        ],
        if (isMobile) ...[
          _buildMobileMenuButton(context),
          const SizedBox(width: 12),
        ],
        _buildProfileDropdown(context, controller, isDesktop),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return const _NotificationBell();
  }

  Widget _buildMobileMenuButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showMobileMenu(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const Icon(
            Icons.menu,
            color: Colors.white70,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDropdown(
    BuildContext context,
    AdminSignInController controller,
    bool showLabel,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 60),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1A1A),
      elevation: 20,
      shadowColor: Colors.black.withOpacity(0.5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: const Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 12),
                const Text(
                  "Admin",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white70,
                size: 18,
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (context) => [
        _buildProfileMenuItem(
          icon: Icons.person_outline,
          title: 'Profile Settings',
          value: 'profile',
        ),
        _buildProfileMenuItem(
          icon: Icons.security,
          title: 'Security',
          value: 'security',
        ),
        _buildProfileMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          value: 'help',
        ),
        const PopupMenuDivider(height: 1),
        _buildProfileMenuItem(
          icon: Icons.logout,
          title: 'Sign Out',
          value: 'signout',
          isDestructive: true,
        ),
      ],
      onSelected: (value) {
        if (value == 'signout') {
          _showWebSignOutDialog(context, controller);
        }
        // Handle other menu items
      },
    );
  }

  PopupMenuItem<String> _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String value,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red : Colors.white70,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ..._getMenuItems()
                .map((item) => _buildMobileMenuItem(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(BuildContext context, _MenuItem item) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, item.route);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SvgPicture.asset(
              item.iconPath,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
            ),
            const SizedBox(width: 16),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWebSignOutDialog(
      BuildContext context, AdminSignInController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1A1A1A),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Are you sure you want to sign out of your admin account? You'll need to log in again to access the dashboard.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.signOut();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Sign Out",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_MenuItem> _getMenuItems() {
    return [
      _MenuItem("Dashboard", "assets/icons/menu_dashboard.svg", '/Dashboard'),
      _MenuItem("Quiz", "assets/icons/menu_doc.svg", '/quiz'),
      _MenuItem("Blog", "assets/icons/menu_doc.svg", '/Blog'),
      _MenuItem("Videos", "assets/icons/media.svg", '/Videos'),
      _MenuItem("Movies", "assets/icons/media.svg", '/Movies'),
      _MenuItem("Users", "assets/icons/menu_profile.svg", '/Users'),
      _MenuItem(
          "Subscriptions", "assets/icons/menu_profile.svg", '/subscriptions'),
      _MenuItem("Live Videos", "assets/icons/live.svg", '/live'),
      _MenuItem("Invoices", "assets/icons/menu_profile.svg", '/invoices'),
      _MenuItem("Advertisement", "assets/icons/menu_profile.svg", '/ads'),
      _MenuItem("Tickets", "assets/icons/menu_profile.svg", '/tickets'),
      _MenuItem(
          "Reconciliation", "assets/icons/menu_profile.svg", '/reconciliation'),
      _MenuItem("Notifications", "assets/icons/menu_profile.svg", '/noti'),
      _MenuItem("Creators", "assets/icons/menu_profile.svg", '/creators'),
      _MenuItem("Custom Notification", "assets/icons/menu_profile.svg", '/custom_notification'),
      _MenuItem("Earnings Settings", "assets/icons/menu_profile.svg", '/earnings_settings'),
      _MenuItem("Website Videos", "assets/icons/media.svg", '/website_videos'),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _MenuItem {
  final String title;
  final String iconPath;
  final String route;

  _MenuItem(this.title, this.iconPath, this.route);
}

// ── Live notification bell with dropdown panel ─────────────────────────────────
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  // Holds the live list of unread ticket snapshots
  List<Map<String, dynamic>> _unread = [];
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('tickets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markRead(String ticketId) async {
    try {
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .update({'isRead': true});
    } catch (_) {}
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return '';
    final dt = (ts as Timestamp).toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _unread = snapshot.data!.docs
              .where((d) => (d.data() as Map<String, dynamic>)['isRead'] != true)
              .map((d) => {
                    ...(d.data() as Map<String, dynamic>),
                    '_id': d.id,
                  })
              .toList();
        }

        final count = _unread.length;

        return PopupMenuButton<String>(
          offset: const Offset(0, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          color: const Color(0xFF12122A),
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.6),
          onSelected: (value) {
            if (value == '__all__') {
              Get.toNamed('/tickets');
            } else {
              _markRead(value);
              Get.toNamed('/tickets');
            }
          },
          itemBuilder: (context) {
            if (_unread.isEmpty) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      children: const [
                        SizedBox(height: 12),
                        Icon(Icons.notifications_off_outlined,
                            color: Colors.white24, size: 40),
                        SizedBox(height: 10),
                        Text('No new notifications',
                            style: TextStyle(color: Colors.white38, fontSize: 14)),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ];
            }

            final items = <PopupMenuEntry<String>>[];

            // Header label
            items.add(PopupMenuItem(
              enabled: false,
              height: 44,
              child: SizedBox(
                width: 320,
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '$count new ticket${count == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ));

            items.add(const PopupMenuDivider());

            // Up to 6 unread tickets
            for (final ticket in _unread.take(6)) {
              final id = ticket['_id'] as String;
              final subject = ticket['subject'] ?? 'Support Request';
              final category = ticket['category'] ?? '';
              final name = ticket['name'] ?? 'User';
              final time = _timeAgo(ticket['createdAt']);

              items.add(PopupMenuItem<String>(
                value: id,
                height: 72,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  width: 320,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.red.shade400, width: 3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                subject,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ));
            }

            if (_unread.length > 6) {
              items.add(PopupMenuItem(
                enabled: false,
                height: 32,
                child: Center(
                  child: Text(
                    '+${_unread.length - 6} more tickets',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ),
              ));
            }

            items.add(const PopupMenuDivider());

            // Footer — "View all"
            items.add(PopupMenuItem<String>(
              value: '__all__',
              height: 44,
              child: SizedBox(
                width: 320,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.open_in_new, size: 15, color: Color(0xFF00D4FF)),
                    SizedBox(width: 6),
                    Text(
                      'View all tickets',
                      style: TextStyle(
                        color: Color(0xFF00D4FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ));

            return items;
          },
          // The bell icon itself
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: count > 0
                      ? Colors.red.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
                color: count > 0
                    ? Colors.red.withOpacity(0.08)
                    : Colors.transparent,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    count > 0
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    color: count > 0 ? Colors.red.shade300 : Colors.white70,
                    size: 22,
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
