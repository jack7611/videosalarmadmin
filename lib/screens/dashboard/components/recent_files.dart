import 'package:admin/constants.dart';
import 'package:admin/controllers/User_controller.dart';
import 'package:admin/models/User.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class UserJoinGraph extends StatefulWidget {
  @override
  _UserJoinGraphState createState() => _UserJoinGraphState();
}

class _UserJoinGraphState extends State<UserJoinGraph> {
  final UserController userController = Get.find<UserController>();

  String selectedTimeRange = 'Last 30 Days';
  final List<String> timeRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'Last Year',
    'All Time'
  ];

  final Map<String, Map<String, dynamic>> _dataCache = {};

  void clearCache() {
    _dataCache.clear();
    setState(() {});
  }

  DateTime getStartDate() {
    DateTime now = DateTime.now();
    switch (selectedTimeRange) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return now.subtract(const Duration(days: 30));
      case 'Last 90 Days':
        return now.subtract(const Duration(days: 90));
      case 'Last Year':
        return now.subtract(const Duration(days: 365));
      default:
        return DateTime(2020);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value) {
        return _buildLoadingWidget();
      }

      if (_dataCache.isNotEmpty) {
        var firstCachedData = _dataCache.values.first;
        if (userController.users.length !=
            (firstCachedData['totalUsers'] ?? 0)) {
          clearCache();
        }
      }

      final graphData = _processUserData();

      return Container(
        width: MediaQuery.of(context).size.width * 0.95,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [secondaryColor, secondaryColor],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(graphData),
              const SizedBox(height: 24),
              _buildTimeRangeSelector(),
              const SizedBox(height: 32),
              _buildChart(graphData),
              const SizedBox(height: 16),
              _buildStats(graphData),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLoadingWidget() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      height: 400,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [secondaryColor, secondaryColor]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent)),
            SizedBox(height: 16),
            Text('Loading user data...',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  String _getDataSourceInfo() {
    int createdAtCount =
        userController.users.where((u) => u.createdAt != null).length;
    int releaseDateCount =
        userController.users.where((u) => u.releaseDate != null).length;
    return 'createdAt: $createdAtCount, releaseDate: $releaseDateCount';
  }

  Widget _buildHeader(Map<String, dynamic> graphData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Growth Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                      color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10)
                ],
              ),
            ),
          ],
        ),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient:
                    LinearGradient(colors: [Colors.black26, Colors.black26]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${graphData['totalUsers']} Total Users',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: timeRanges.map((range) {
          final isSelected = selectedTimeRange == range;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTimeRange = range;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [Colors.black26, Colors.black26])
                      : null,
                  color: isSelected ? null : Colors.grey[700],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          isSelected ? Colors.transparent : Colors.grey[600]!),
                ),
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> graphData) {
    final registrationData = graphData['registrationData'] as List<FlSpot>;
    final subscriptionData = graphData['subscriptionData'] as List<FlSpot>;
    final sortedDates = graphData['sortedDates'] as List<String>;

    if (registrationData.isEmpty && subscriptionData.isEmpty) {
      return _buildNoDataWidget();
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          _createLineChartData(registrationData, subscriptionData, sortedDates),
          duration: Duration.zero,
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.white38),
            SizedBox(height: 16),
            Text('No user data available',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('Users will appear here once they start joining',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(Map<String, dynamic> graphData) {
    final stats = graphData['stats'] as Map<String, dynamic>;
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                'Peak Day', '${stats['peakDay']} users', Icons.trending_up)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
                'Average', '${stats['average']} users/day', Icons.analytics)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Growth', '+90', Icons.arrow_upward)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 24),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Map<String, dynamic> _processUserData() {
    if (_dataCache.containsKey(selectedTimeRange)) {
      return _dataCache[selectedTimeRange]!;
    }

    Map<String, int> userJoinCount = {};
    Map<String, int> subscriptionCount = {};
    DateTime startDate = getStartDate();
    DateTime endDate = DateTime.now();
    int totalUsers = userController.users.length;

    List<User> registrationUsers =
        userController.getUsersInRegistrationDateRange(startDate, endDate);
    List<User> subscriptionUsers =
        userController.getUsersInSubscriptionDateRange(startDate, endDate);

    print("Number of registration users: ${registrationUsers.length}");

    print("Number of subscription users: ${subscriptionUsers.length}");
   

    for (var user in registrationUsers) {
      if (user.registrationDate != null) {
        String formattedDate =
            DateFormat('dd-MM-yyyy').format(user.registrationDate!);
        userJoinCount[formattedDate] = (userJoinCount[formattedDate] ?? 0) + 1;
      }
    }

    for (var user in subscriptionUsers) {
      if (user.subscriptionStartDate != null) {
        String formattedDate =
            DateFormat('dd-MM-yyyy').format(user.subscriptionStartDate!);
        subscriptionCount[formattedDate] =
            (subscriptionCount[formattedDate] ?? 0) + 1;
      }
    }

    Set<String> allDates = {...userJoinCount.keys, ...subscriptionCount.keys};

    if (allDates.isEmpty) {
      final emptyData = {
        'registrationData': <FlSpot>[],
        'subscriptionData': <FlSpot>[],
        'sortedDates': <String>[],
        'totalUsers': totalUsers,
        'filteredUsers': 0,
        'stats': {'peakDay': 0, 'average': 0, 'growth': 0},
      };
      _dataCache[selectedTimeRange] = emptyData;
      return emptyData;
    }

    List<String> sortedDates = allDates.toList()
      ..sort((a, b) => DateFormat('dd-MM-yyyy')
          .parse(a)
          .compareTo(DateFormat('dd-MM-yyyy').parse(b)));

    final registrationData = sortedDates.asMap().entries.map((entry) {
      return FlSpot(
          entry.key.toDouble(), (userJoinCount[entry.value] ?? 0).toDouble());
    }).toList();

    final subscriptionData = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(),
          (subscriptionCount[entry.value] ?? 0).toDouble());
    }).toList();

    List<int> dailyCounts = userJoinCount.values.toList();
    int peakDay = dailyCounts.isNotEmpty
        ? dailyCounts.reduce((a, b) => a > b ? a : b)
        : 0;
    double average = dailyCounts.isNotEmpty
        ? dailyCounts.reduce((a, b) => a + b) / dailyCounts.length
        : 0;
    double growth = dailyCounts.length >= 2
        ? ((dailyCounts.last - dailyCounts.first) /
            (dailyCounts.first == 0 ? 1 : dailyCounts.first) *
            100)
        : 0;
    int filteredUsers = dailyCounts.fold(0, (sum, count) => sum + count);

    final processedData = {
      'registrationData': registrationData,
      'subscriptionData': subscriptionData,
      'sortedDates': sortedDates,
      'totalUsers': totalUsers,
      'filteredUsers': filteredUsers,
      'stats': {
        'peakDay': peakDay,
        'average': average.round(),
        'growth': growth.round()
      },
    };

    _dataCache[selectedTimeRange] = processedData;
    return processedData;
  }

  LineChartData _createLineChartData(List<FlSpot> registrationData,
      List<FlSpot> subscriptionData, List<String> sortedDates) {
    double maxY = (registrationData + subscriptionData)
            .fold<double>(0, (max, spot) => spot.y > max ? spot.y : max) +
        2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        verticalInterval:
            sortedDates.length > 10 ? (sortedDates.length / 5) : 1,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: sortedDates.length > 10 ? (sortedDates.length / 5) : 1,
            getTitlesWidget: (value, meta) =>
                _getBottomTitles(value, sortedDates),
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(value.toInt().toString(),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: Colors.white.withOpacity(0.2))),
      minX: 0,
      maxX: (sortedDates.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: registrationData,
          isCurved: true,
          gradient: const LinearGradient(
              colors: [Colors.redAccent, Colors.redAccent]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.redAccent),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.redAccent.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
        LineChartBarData(
          spots: subscriptionData,
          isCurved: true,
          gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.blueAccent]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.blueAccent),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blueAccent.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              int index = touchedSpot.spotIndex;

              if (index < sortedDates.length) {
                String date = DateFormat('MMM d, yyyy')
                    .format(DateFormat('dd-MM-yyyy').parse(sortedDates[index]));

                String tooltipText = '';

                if (touchedSpot.barIndex == 0) {
                  int userCount = registrationData[index].y.round();
                  tooltipText = '$date\n$userCount users registered';
                } else if (touchedSpot.barIndex == 1) {
                  int subCount = subscriptionData[index].y.round();
                  tooltipText = '$subCount users subscribed';
                }

                return LineTooltipItem(
                    tooltipText,
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14));
              }

              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _getBottomTitles(double value, List<String> sortedDates) {
    if (sortedDates.isEmpty ||
        value.toInt() >= sortedDates.length ||
        value.toInt() < 0) {
      return const SizedBox.shrink();
    }
    int index = value.toInt();
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('dd-MM-yyyy').parse(sortedDates[index]);
    } catch (e) {
      return const SizedBox.shrink();
    }
    String displayText = (index == sortedDates.length - 1)
        ? "Today"
        : DateFormat('MMM d').format(parsedDate);
    return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(displayText,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500)));
  }
}
