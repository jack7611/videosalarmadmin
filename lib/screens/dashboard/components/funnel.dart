import 'package:admin/controllers/User_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class FunnelData {
  final int totalUsers;
  final int registeredUsers;
  final int subscribedUsers;

  const FunnelData({
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

// ── Widget ────────────────────────────────────────────────────────────────────
class ConversionFunnelWidget extends StatelessWidget {
  const ConversionFunnelWidget({Key? key}) : super(key: key);

  static const _bg     = Color(0xFF1A1A35);
  static const _border = Color(0xFF2D3748);
  static const _cyan   = Color(0xFF00D4FF);
  static const _green  = Color(0xFF00B894);
  static const _purple = Color(0xFF6C5CE7);
  static const _textPrimary   = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFB2B7C1);
  static const _textMuted     = Color(0xFF74788D);

  FunnelData _calculate(List users) {
    final total    = users.where((u) => !u.isDeleted).length;
    final reg      = users.where((u) => !u.isDeleted && u.registrationDate != null).length;
    final subbed   = users.where((u) =>
        !u.isDeleted && u.active == true && u.subscriptionStartDate != null).length;
    return FunnelData(totalUsers: total, registeredUsers: reg, subscribedUsers: subbed);
  }

  @override
  Widget build(BuildContext context) {
    final userCtrl = Get.find<UserController>();

    return Obx(() {
      final data = _calculate(userCtrl.users);

      return Container(
        padding: const EdgeInsets.all(defaultPadding * 1.5),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_purple, _cyan]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.analytics_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('Conversion Funnel',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary)),
                  SizedBox(height: 2),
                  Text('Registration → subscription journey',
                      style: TextStyle(fontSize: 12, color: _textSecondary)),
                ]),
              ),
            ]),
            const SizedBox(height: defaultPadding * 1.5),

            // Funnel steps
            _FunnelStep(
              label: 'Total Users',
              count: data.totalUsers,
              percentage: 100,
              color: _cyan,
              icon: Icons.people_rounded,
              widthFraction: 1.0,
            ),
            _FunnelArrow(),
            _FunnelStep(
              label: 'Registered',
              count: data.registeredUsers,
              percentage: data.registrationConversionRate,
              color: _green,
              icon: Icons.person_add_rounded,
              widthFraction: 0.85,
            ),
            _FunnelArrow(),
            _FunnelStep(
              label: 'Paid Subscribers',
              count: data.subscribedUsers,
              percentage: data.subscriptionConversionRate,
              color: _purple,
              icon: Icons.star_rounded,
              widthFraction: 0.60,
            ),

            const SizedBox(height: defaultPadding * 1.5),

            // Metrics row
            Row(children: [
              Expanded(child: _MetricCard(
                title: 'Registration Rate',
                value: '${data.registrationConversionRate.toStringAsFixed(1)}%',
                sub: '${data.registeredUsers} / ${data.totalUsers}',
                color: _green,
              )),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(
                title: 'Subscription Rate',
                value: '${data.subscriptionConversionRate.toStringAsFixed(1)}%',
                sub: '${data.subscribedUsers} / ${data.totalUsers}',
                color: _purple,
              )),
              const SizedBox(width: 10),
              Expanded(child: _MetricCard(
                title: 'Reg → Sub Rate',
                value: '${data.registrationToSubscriptionRate.toStringAsFixed(1)}%',
                sub: '${data.subscribedUsers} / ${data.registeredUsers}',
                color: const Color(0xFFFFD93D),
              )),
            ]),
          ],
        ),
      );
    });
  }
}

// ── Funnel step ───────────────────────────────────────────────────────────────
class _FunnelStep extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;
  final IconData icon;
  final double widthFraction;

  const _FunnelStep({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.widthFraction,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFraction,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.22), color.withOpacity(0.08)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE8E8E8))),
                  Text('${percentage.toStringAsFixed(1)}% of total',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF74788D))),
                ],
              ),
            ),
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FunnelArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 2, height: 20, color: const Color(0xFF2D3748)),
      ]),
    );
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 2),
        Text(sub,
            style: const TextStyle(fontSize: 10, color: Color(0xFF74788D))),
      ]),
    );
  }
}
