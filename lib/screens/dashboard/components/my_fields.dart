import 'package:admin/controllers/User_controller.dart';
import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/controllers/movie_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/recent_files.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../constants.dart';
import 'funnel.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class DashboardTheme {
  static const Color backgroundColor = Color(0xFF0A0A1A);
  static const Color surfaceColor    = Color(0xFF12122A);
  static const Color cardColor       = Color(0xFF1A1A35);
  static const Color accentColor     = Color(0xFF00D4FF);
  static const Color primaryColor    = Color(0xFF6C5CE7);
  static const Color successColor    = Color(0xFF00B894);
  static const Color warningColor    = Color(0xFFE17055);
  static const Color roseColor       = Color(0xFFFF6B9D);
  static const Color goldColor       = Color(0xFFFFD93D);
  static const Color textPrimary     = Color(0xFFFFFFFF);
  static const Color textSecondary   = Color(0xFFB2B7C1);
  static const Color textMuted       = Color(0xFF74788D);
  static const Color borderColor     = Color(0xFF2D3748);

  static BoxDecoration cardDecoration({Color? glowColor}) => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
    boxShadow: [
      BoxShadow(
        color: (glowColor ?? Colors.black).withOpacity(glowColor != null ? 0.18 : 0.35),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: glowColor != null ? 2 : 0,
      ),
    ],
  );
}

// ── Root widget ───────────────────────────────────────────────────────────────
class MyFiles extends StatelessWidget {
  const MyFiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardTheme.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(),
            const SizedBox(height: defaultPadding * 2),
            const _StatsGrid(),
            const SizedBox(height: defaultPadding * 2),
            Responsive(
              mobile: Column(children: [
                const ConversionFunnelWidget(),
                const SizedBox(height: defaultPadding * 2),
                UserJoinGraph(),
              ]),
              tablet: Column(children: [
                const ConversionFunnelWidget(),
                const SizedBox(height: defaultPadding * 2),
                UserJoinGraph(),
              ]),
              desktop: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 2, child: const ConversionFunnelWidget()),
                const SizedBox(width: defaultPadding),
                Expanded(flex: 3, child: UserJoinGraph()),
              ]),
            ),
            const SizedBox(height: defaultPadding * 2),
            const _QuickActions(),
            const SizedBox(height: defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(now);
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A4E), Color(0xFF0F0F2D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DashboardTheme.primaryColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: DashboardTheme.primaryColor.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: DashboardTheme.accentColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.movie, color: Color(0xFF6C5CE7), size: 36)),
          ),
          const SizedBox(width: 18),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting, Admin',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: DashboardTheme.textPrimary,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('Videos Alarm — Dashboard Overview',
                    style: TextStyle(
                        fontSize: 13, color: DashboardTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: TextStyle(fontSize: 12, color: DashboardTheme.textMuted)),
              ],
            ),
          ),

          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                DashboardTheme.successColor,
                DashboardTheme.successColor.withOpacity(0.75),
              ]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: DashboardTheme.successColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.circle, color: Colors.white, size: 8),
              SizedBox(width: 6),
              Text('LIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ────────────────────────────────────────────────────────────────
class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final userCtrl    = Get.find<UserController>();
    final videoCtrl   = Get.find<VideosController>();
    final blogCtrl    = Get.find<BlogController>();
    final movieCtrl   = Get.find<MovieController>();
    final creatorCtrl = Get.find<CreatorController>();

    return Obx(() {
      final subscribers = userCtrl.users
          .where((u) => !u.isDeleted && u.active == true && u.subscriptionStartDate != null)
          .length;

      final stats = [
        _StatData('Movies',    movieCtrl.movies.length,            Icons.movie_rounded,        DashboardTheme.primaryColor, '/Movies'),
        _StatData('Videos',    videoCtrl.videos.length,            Icons.play_circle_rounded,  DashboardTheme.accentColor,  '/Videos'),
        _StatData('Users',     userCtrl.users.length,              Icons.people_rounded,        DashboardTheme.successColor, '/Users'),
        _StatData('Subscribers', subscribers,                       Icons.star_rounded,         DashboardTheme.goldColor,    '/subscriptions'),
        _StatData('Creators',  creatorCtrl.creators.length,        Icons.videocam_rounded,     DashboardTheme.roseColor,    '/creators'),
        _StatData('Blogs',     blogCtrl.blogData.length,           Icons.article_rounded,      DashboardTheme.warningColor, '/Blog'),
      ];

      return LayoutBuilder(builder: (ctx, constraints) {
        int cols = constraints.maxWidth < 500 ? 2 : constraints.maxWidth < 900 ? 3 : 6;
        double aspect = constraints.maxWidth < 500 ? 1.3 : 1.5;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspect,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => _StatCard(data: stats[i]),
        );
      });
    });
  }
}

class _StatData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final String route;
  const _StatData(this.label, this.count, this.icon, this.color, this.route);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(data.route),
        child: Container(
          decoration: DashboardTheme.cardDecoration(glowColor: data.color),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        data.color.withOpacity(0.3),
                        data.color.withOpacity(0.1),
                      ]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(data.icon, color: data.color, size: 20),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12, color: DashboardTheme.textMuted),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.count.toString(),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: data.color,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(data.label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DashboardTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData('Upload Movie',   Icons.add_circle_rounded,   DashboardTheme.primaryColor, '/Movies'),
      _ActionData('Manage Users',   Icons.manage_accounts,       DashboardTheme.successColor, '/Users'),
      _ActionData('Advertisements', Icons.campaign_rounded,      DashboardTheme.accentColor,  '/ads'),
      _ActionData('Invoices',       Icons.receipt_long_rounded,  DashboardTheme.goldColor,    '/invoices'),
      _ActionData('Creators',       Icons.videocam_rounded,      DashboardTheme.roseColor,    '/creators'),
      _ActionData('Earnings',       Icons.account_balance_wallet_rounded, DashboardTheme.warningColor, '/earnings_settings'),
    ];

    return Container(
      padding: const EdgeInsets.all(defaultPadding * 1.5),
      decoration: DashboardTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  DashboardTheme.accentColor,
                  DashboardTheme.primaryColor,
                ]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: DashboardTheme.textPrimary)),
          ]),
          const SizedBox(height: defaultPadding),
          Responsive(
            mobile: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions.map(_buildBtn).toList()),
            tablet: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: actions.map(_buildBtn).toList()),
            desktop: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: actions.map(_buildBtn).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(_ActionData a) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Get.toNamed(a.route),
        child: Container(
          width: 110,
          height: 88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                a.color.withOpacity(0.18),
                a.color.withOpacity(0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: a.color.withOpacity(0.35), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a.icon, color: a.color, size: 30),
              const SizedBox(height: 8),
              Text(a.label,
                  style: TextStyle(
                      color: DashboardTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionData {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ActionData(this.label, this.icon, this.color, this.route);
}

// ── Funnel + graph kept as-is from their own files ────────────────────────────
class FileInfoCardGridView extends StatelessWidget {
  const FileInfoCardGridView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const _StatsGrid();
}
