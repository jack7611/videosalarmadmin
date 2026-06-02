import 'package:admin/controllers/User_controller.dart';
import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/funnel.dart';
import 'package:admin/screens/dashboard/components/recent_files.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants.dart';
import 'file_info_card.dart';

// Dark Theme Constants
class DashboardTheme {
  static const Color backgroundColor = Color(0xFF0F0F23);
  static const Color surfaceColor = Color(0xFF1A1A2E);
  static const Color cardColor = Color(0xFF16213E);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color successColor = Color(0xFF00B894);
  static const Color warningColor = Color(0xFFE17055);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB2B7C1);
  static const Color textMuted = Color(0xFF74788D);
  static const Color borderColor = Color(0xFF2D3748);
  
  static BoxDecoration cardDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cardColor,
        cardColor.withOpacity(0.8),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        offset: Offset(0, 8),
        spreadRadius: 2,
      ),
    ],
  );
  
  static BoxDecoration glassDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.white.withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );
}

class MyFiles extends StatelessWidget {
  const MyFiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardTheme.backgroundColor,
            DashboardTheme.surfaceColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: defaultPadding * 2),
            
            Responsive(
              mobile: _buildMobileLayout(),
              tablet: _buildTabletLayout(), 
              desktop: _buildDesktopLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding * 1.5),
      decoration: DashboardTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [DashboardTheme.accentColor, DashboardTheme.primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: DashboardTheme.accentColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dashboard Overview",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: DashboardTheme.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Monitor your platform's key metrics and performance",
                        style: TextStyle(
                          color: DashboardTheme.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DashboardTheme.successColor, DashboardTheme.successColor.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.trending_up, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  "Live",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStatsCards(),
        SizedBox(height: defaultPadding * 2),
        _buildAnalyticsSection(),
        SizedBox(height: defaultPadding * 2),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        _buildStatsCards(),
        SizedBox(height: defaultPadding * 2),
        _buildAnalyticsSection(),
        SizedBox(height: defaultPadding * 2),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildStatsCards(),
        SizedBox(height: defaultPadding * 2),
        _buildAnalyticsSection(),
        SizedBox(height: defaultPadding * 2),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Container(
      constraints: BoxConstraints(maxHeight: 220),
      child: FileInfoCardGridView(),
    );
  }

  Widget _buildAnalyticsSection() {
    return Responsive(
      mobile: Column(
        children: [
          _buildCompactConversionFunnel(),
          SizedBox(height: defaultPadding * 2),
          _buildCompactUserGraph(),
        ],
      ),
      tablet: Column(
        children: [
          _buildCompactConversionFunnel(),
          SizedBox(height: defaultPadding * 2), 
          _buildCompactUserGraph(),
        ],
      ),
      desktop: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildCompactConversionFunnel(),
          ),
          SizedBox(width: defaultPadding),
          Expanded(
            flex: 3,
            child: _buildCompactUserGraph(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(defaultPadding * 1.5),
      decoration: DashboardTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: DashboardTheme.accentColor, size: 24),
              SizedBox(width: 12),
              Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DashboardTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: defaultPadding),
          Responsive(
            mobile: Column(
              children: _buildActionButtons(),
            ),
            tablet: Wrap(
              spacing: defaultPadding,
              runSpacing: defaultPadding,
              children: _buildActionButtons(),
            ),
            desktop: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      _buildActionButton(Icons.add_circle, "Add Video", DashboardTheme.accentColor),
      _buildActionButton(Icons.person_add, "Add User", DashboardTheme.successColor),
      _buildActionButton(Icons.article, "New Blog", DashboardTheme.primaryColor),
      _buildActionButton(Icons.settings, "Settings", DashboardTheme.warningColor),
    ];
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: DashboardTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactConversionFunnel() {
    return ConversionFunnelWidget();
  }

  Widget _buildCompactUserGraph() {
    return UserJoinGraph();
  }
}

class FileInfoCardGridView extends StatelessWidget {
  const FileInfoCardGridView({
    Key? key,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
  }) : super(key: key);

  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final VideosController videosController = Get.put(VideosController());
    final BlogController blogController = Get.find<BlogController>();

    return Obx(() {
      final subscribedUsersCount = userController.users
          .where((user) => 
              !user.isDeleted && 
              user.active == true && 
              user.subscriptionStartDate != null)
          .length;

      return LayoutBuilder(
        builder: (context, constraints) {
          int columns = 4;
          if (constraints.maxWidth < 600) {
            columns = 2;
          } else if (constraints.maxWidth < 900) {
            columns = 3;
          }

          return GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: constraints.maxWidth < 600 ? 1.5 : 1.8,
            children: [
              DarkFileInfoCard(
                numOfFiles: videosController.videos.length,
                icon: Icons.play_circle_filled,
                title: "Videos",
                subtitle: "Library",
                color: DashboardTheme.accentColor,
                trend: 12.5,
              ),
              DarkFileInfoCard(
                numOfFiles: userController.users.length,
                icon: Icons.people,
                title: "Users",
                subtitle: "Total",
                color: DashboardTheme.successColor,
                trend: 8.3,
              ),
              DarkFileInfoCard(
                numOfFiles: subscribedUsersCount,
                icon: Icons.star,
                title: "Subscribers",
                subtitle: "Premium",
                color: DashboardTheme.primaryColor,
                trend: 15.7,
              ),
              DarkFileInfoCard(
                numOfFiles: blogController.blogData.length,
                icon: Icons.article,
                title: "Blogs",
                subtitle: "Posts",
                color: DashboardTheme.warningColor,
                trend: 5.2,
              ),
            ],
          );
        },
      );
    });
  }
}

class DarkFileInfoCard extends StatelessWidget {
  const DarkFileInfoCard({
    Key? key,
    required this.numOfFiles,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trend = 0,
  }) : super(key: key);

  final int numOfFiles;
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final double trend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashboardTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trend > 0 ? DashboardTheme.successColor.withOpacity(0.2) : 
                               Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trend > 0 ? Icons.trending_up : Icons.trending_down,
                            color: trend > 0 ? DashboardTheme.successColor : Colors.red,
                            size: 10,
                          ),
                          SizedBox(width: 2),
                          Text(
                            "${trend.abs()}%",
                            style: TextStyle(
                              color: trend > 0 ? DashboardTheme.successColor : Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  numOfFiles.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DashboardTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DashboardTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: DashboardTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConversionFunnelWidget extends StatelessWidget {
  const ConversionFunnelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();

    return Obx(() {
      final funnelData = _calculateFunnelData(userController.users);
      
      return Container(
        constraints: BoxConstraints(
          minHeight: 400,
          maxHeight: 600,
        ),
        padding: EdgeInsets.all(defaultPadding * 1.5),
        decoration: DashboardTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFunnelHeader(context),
            SizedBox(height: defaultPadding * 1.5),
            Expanded(
              child: _buildCompactFunnelSteps(context, funnelData),
            ),
            SizedBox(height: defaultPadding),
            _buildCompactMetrics(context, funnelData),
          ],
        ),
      );
    });
  }

  Widget _buildFunnelHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DashboardTheme.primaryColor, DashboardTheme.accentColor],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: DashboardTheme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(Icons.analytics, color: Colors.white, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Conversion Funnel",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DashboardTheme.textPrimary,
                ),
              ),
              Text(
                "Registration to subscription journey",
                style: TextStyle(
                  color: DashboardTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactFunnelSteps(BuildContext context, FunnelData data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactFunnelStep(
          context, "Total Users", data.totalUsers, 100.0, DashboardTheme.accentColor, Icons.people),
        _buildFunnelArrow(),
        _buildCompactFunnelStep(
          context, "Registered", data.registeredUsers, 
          data.registrationConversionRate, DashboardTheme.successColor, Icons.person_add),
        _buildFunnelArrow(),
        _buildCompactFunnelStep(
          context, "Subscribers", data.subscribedUsers, 
          data.subscriptionConversionRate, DashboardTheme.primaryColor, Icons.star),
      ],
    );
  }

  Widget _buildCompactFunnelStep(
      BuildContext context, String title, int count, double percentage, Color color, IconData icon) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: DashboardTheme.textPrimary)),
                      Text("${percentage.toStringAsFixed(1)}% conversion", 
                        style: TextStyle(
                          fontSize: 12, 
                          color: DashboardTheme.textSecondary)),
                    ],
                  ),
                ),
                Text(count.toString(),
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFunnelArrow() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Icon(Icons.keyboard_double_arrow_down, 
        color: DashboardTheme.textMuted, size: 28),
    );
  }

  Widget _buildCompactMetrics(BuildContext context, FunnelData data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DashboardTheme.surfaceColor.withOpacity(0.5),
            DashboardTheme.surfaceColor.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem("Registration Rate", 
            "${data.registrationConversionRate.toStringAsFixed(1)}%", DashboardTheme.successColor),
          _buildMetricItem("Subscription Rate", 
            "${data.subscriptionConversionRate.toStringAsFixed(1)}%", DashboardTheme.primaryColor),
          _buildMetricItem("Reg→Sub Rate", 
            "${data.registrationToSubscriptionRate.toStringAsFixed(1)}%", DashboardTheme.accentColor),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, 
          style: TextStyle(
            fontSize: 12, 
            color: DashboardTheme.textSecondary,
            fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
        SizedBox(height: 8),
        Text(value, 
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.bold, 
            color: color)),
      ],
    );
  }

  FunnelData _calculateFunnelData(List users) {
    final totalUsers = users.where((user) => !user.isDeleted).length;
    final registeredUsers = users.where((user) =>
        !user.isDeleted && user.registrationDate != null).length;
    final subscribedUsers = users.where((user) =>
        !user.isDeleted &&
        user.active == true &&
        user.subscriptionStartDate != null).length;

    return FunnelData(
      totalUsers: totalUsers,
      registeredUsers: registeredUsers,
      subscribedUsers: subscribedUsers,
    );
  }
}

class FunnelData {
  final int totalUsers;
  final int registeredUsers;
  final int subscribedUsers;

  FunnelData({
    required this.totalUsers,
    required this.registeredUsers,
    required this.subscribedUsers,
  });

  double get registrationConversionRate =>
      totalUsers > 0 ? (registeredUsers / totalUsers) * 100 : 0;

  double get subscriptionConversionRate =>
      totalUsers > 0 ? (subscribedUsers / totalUsers) * 100 : 0;

  double get registrationToSubscriptionRate =>
      registeredUsers > 0 ? (subscribedUsers / registeredUsers) * 100 : 0;
}