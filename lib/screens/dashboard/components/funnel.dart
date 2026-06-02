import 'package:admin/controllers/User_controller.dart';
import 'package:admin/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants.dart';

class ConversionFunnelWidget extends StatelessWidget {
  const ConversionFunnelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    
    return Obx(() {
      final funnelData = _calculateFunnelData(userController.users);
      
      return Container(
        margin: EdgeInsets.all(defaultPadding),
        padding: EdgeInsets.all(defaultPadding * 1.5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Registration to Payment Conversion Funnel",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Track user journey from registration to subscription",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: defaultPadding * 1.5),
            _buildFunnelSteps(context, funnelData),
            SizedBox(height: defaultPadding * 1.5),
            _buildConversionMetrics(context, funnelData),
          ],
        ),
      );
    });
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

  Widget _buildFunnelSteps(BuildContext context, FunnelData data) {
    return Column(
      children: [
        _buildFunnelStep(
          context,
          "Total Users",
          data.totalUsers,
          data.totalUsers,
          100.0,
          Colors.blue.shade100,
          Colors.blue.shade600,
          true,
        ),
        _buildFunnelConnector(context),
        _buildFunnelStep(
          context,
          "Registered Users",
          data.registeredUsers,
          data.totalUsers,
          data.registrationConversionRate,
          Colors.green.shade100,
          Colors.green.shade600,
          false,
        ),
        _buildFunnelConnector(context),
        _buildFunnelStep(
          context,
          "Paid Subscribers",
          data.subscribedUsers,
          data.totalUsers,
          data.subscriptionConversionRate,
          Colors.purple.shade100,
          Colors.purple.shade600,
          false,
        ),
      ],
    );
  }

  Widget _buildFunnelStep(
    BuildContext context,
    String title,
    int count,
    int totalCount,
    double percentage,
    Color backgroundColor,
    Color borderColor,
    bool isFirst,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.8;
    final stepWidth = isFirst ? maxWidth : maxWidth * (percentage / 100);
    
    return Container(
      width: stepWidth,
      height: 80,
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: borderColor,
              ),
            ),
            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 12,
                color: borderColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelConnector(BuildContext context) {
    return Container(
      width: 2,
      height: 20,
      color: Colors.grey.shade400,
      margin: EdgeInsets.symmetric(vertical: 4),
    );
  }

  Widget _buildConversionMetrics(BuildContext context, FunnelData data) {
    return Responsive(
      mobile: Column(
        children: [
          _buildMetricCard(
            context,
            "Registration Rate",
            "${data.registrationConversionRate.toStringAsFixed(1)}%",
            "${data.registeredUsers} / ${data.totalUsers}",
            Colors.green,
          ),
          SizedBox(height: defaultPadding),
          _buildMetricCard(
            context,
            "Subscription Rate",
            "${data.subscriptionConversionRate.toStringAsFixed(1)}%",
            "${data.subscribedUsers} / ${data.totalUsers}",
            Colors.purple,
          ),
          SizedBox(height: defaultPadding),
          _buildMetricCard(
            context,
            "Reg to Sub Rate",
            "${data.registrationToSubscriptionRate.toStringAsFixed(1)}%",
            "${data.subscribedUsers} / ${data.registeredUsers}",
            Colors.orange,
          ),
        ],
      ),
      tablet: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              context,
              "Registration Rate",
              "${data.registrationConversionRate.toStringAsFixed(1)}%",
              "${data.registeredUsers} / ${data.totalUsers}",
              Colors.green,
            ),
          ),
          SizedBox(width: defaultPadding),
          Expanded(
            child: _buildMetricCard(
              context,
              "Subscription Rate",
              "${data.subscriptionConversionRate.toStringAsFixed(1)}%",
              "${data.subscribedUsers} / ${data.totalUsers}",
              Colors.purple,
            ),
          ),
          SizedBox(width: defaultPadding),
          Expanded(
            child: _buildMetricCard(
              context,
              "Reg to Sub Rate",
              "${data.registrationToSubscriptionRate.toStringAsFixed(1)}%",
              "${data.subscribedUsers} / ${data.registeredUsers}",
              Colors.orange,
            ),
          ),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              context,
              "Registration Rate",
              "${data.registrationConversionRate.toStringAsFixed(1)}%",
              "${data.registeredUsers} / ${data.totalUsers}",
              Colors.green,
            ),
          ),
          SizedBox(width: defaultPadding),
          Expanded(
            child: _buildMetricCard(
              context,
              "Subscription Rate",
              "${data.subscriptionConversionRate.toStringAsFixed(1)}%",
              "${data.subscribedUsers} / ${data.totalUsers}",
              Colors.purple,
            ),
          ),
          SizedBox(width: defaultPadding),
          Expanded(
            child: _buildMetricCard(
              context,
              "Reg to Sub Rate",
              "${data.registrationToSubscriptionRate.toStringAsFixed(1)}%",
              "${data.subscribedUsers} / ${data.registeredUsers}",
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String percentage,
    String ratio,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            percentage,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            ratio,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
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