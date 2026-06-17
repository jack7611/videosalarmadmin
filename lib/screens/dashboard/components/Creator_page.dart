import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/models/Creator.dart';
import 'package:admin/screens/dashboard/components/creator_detail_page.dart';
import 'package:admin/screens/dashboard/components/creator_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreatorPage extends StatelessWidget {
  const CreatorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final creatorController = Get.put(CreatorController());
    return Obx(() {
      if (creatorController.isLoading.value) {
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
                  'Loading creators...',
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
          appBar: _buildAppBar(creatorController, context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildCreatorsTable(creatorController, context),
              ],
            ),
          ),
        );
      }
    });
  }

  PreferredSizeWidget _buildAppBar(CreatorController creatorController, BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Creator Management',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextButton.icon(
            onPressed: () => creatorController.fetchCreators(),
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
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: InkWell(
            onTap: () => _showCreatorFormDialog(context, null),
            borderRadius: BorderRadius.circular(12),
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
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Add Creator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
          'Monitor and manage creator accounts',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white60,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorsTable(CreatorController creatorController, BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.all(24),
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
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Creator Directory',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Obx(() => Text(
                        '${creatorController.filteredCreators.length} creators',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Theme(
              data: Theme.of(context).copyWith(
                iconTheme: const IconThemeData(color: Colors.white),
                textTheme: Theme.of(context).textTheme.copyWith(
                      bodySmall: const TextStyle(color: Colors.white),
                    ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: PaginatedDataTable(
                  key: ValueKey(
                      '${creatorController.rowsPerPage.value}_${creatorController.filteredCreators.hashCode}_${creatorController.creatorEarnings.hashCode}_${creatorController.releaseVersion.value}'),
                  headingRowColor:
                      MaterialStateProperty.all(const Color(0xFF0F0F0F)),
                  horizontalMargin: 0,
                  columnSpacing: 24,
                  rowsPerPage: creatorController.rowsPerPage.value,
                  availableRowsPerPage: const [5, 10, 20, 50],
                  onRowsPerPageChanged: (value) {
                    creatorController.rowsPerPage.value = value!;
                  },
                  columns: [
                    DataColumn(
                      label: Expanded(
                        child: Text('Creator', style: _headerTextStyle()),
                      ),
                    ),
                    DataColumn(
                      label: Text('Company', style: _headerTextStyle()),
                    ),
                    DataColumn(
                      label: Text('Phone', style: _headerTextStyle()),
                    ),
                    DataColumn(
                      label: Text('Email', style: _headerTextStyle()),
                    ),
                    DataColumn(
                      label: Text('Password',style: _headerTextStyle(),),
                      ),
                    DataColumn(
                      label: Text('Status', style: _headerTextStyle()),
                    ),
                    DataColumn(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text('Wallet', style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF10B981),
                            letterSpacing: -0.2,
                          )),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Text('Actions', style: _headerTextStyle()),
                    ),
                  ],
                  source: _CreatorDataSource(
                    creatorController: creatorController,
                    context: context,
                    earnings: creatorController.creatorEarnings,
                    ratePerHour: creatorController.ratePerWatchHour.value,
                  ),
                ),
              ),
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

  void _showCreatorFormDialog(BuildContext context, Creator? creator) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreatorFormDialog(creator: creator);
      },
    );
  }
}

class _CreatorDataSource extends DataTableSource {
  final CreatorController creatorController;
  final BuildContext context;
  final Map<String, double> earnings;
  final double ratePerHour;

  _CreatorDataSource({
    required this.creatorController,
    required this.context,
    required this.earnings,
    required this.ratePerHour,
  });

  @override
  DataRow getRow(int index) {
    if (index >= creatorController.filteredCreators.length) {
      return const DataRow(cells: [
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
        DataCell(Text('')),
      ]);
    }
    final creator = creatorController.filteredCreators[index];
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (creator.name?.isNotEmpty == true)
                        ? creator.name![0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      creator.name ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      creator.email ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              creator.companyName ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              creator.phoneNo ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              creator.email ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              creator.password ?? 'N/A',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (creator.active ?? true) ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (creator.active ?? true) ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Text(
              (creator.active ?? true) ? 'Active' : 'Inactive',
              style: TextStyle(
                color: (creator.active ?? true) ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        DataCell(
          Builder(builder: (context) {
            final available = creatorController.availableWallet(creator.id);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: available > 0
                    ? Colors.green.withOpacity(0.12)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: available > 0
                      ? Colors.green.withOpacity(0.4)
                      : Colors.white10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 14,
                    color: available > 0 ? Colors.greenAccent : Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${available.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: available > 0 ? Colors.greenAccent : Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CreatorDetailPage(creator: creator),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF10B981), size: 20),
                label: const Text('View',
                    style: TextStyle(color: Color(0xFF10B981))),
                style: TextButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF10B981).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return CreatorFormDialog(creator: creator);
                    },
                  );
                },
                icon: const Icon(Icons.edit_rounded,
                    color: Color(0xFF3B82F6), size: 20),
                label: const Text('Edit', style: TextStyle(color: Color(0xFF3B82F6))),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDeleteDialog(context, creatorController, creator),
                icon: const Icon(Icons.delete_rounded,
                    color: Color(0xFFEF4444), size: 20),
                label: const Text('Delete',
                    style: TextStyle(color: Color(0xFFEF4444))),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(width: 8),
              Builder(builder: (context) {
                final available = creatorController.availableWallet(creator.id);
                return TextButton.icon(
                  onPressed: available > 0
                      ? () => _showReleaseDialog(context, creatorController, creator, available)
                      : null,
                  icon: Icon(Icons.payments_rounded,
                      color: available > 0 ? const Color(0xFFF59E0B) : Colors.white24,
                      size: 20),
                  label: Text('Release',
                      style: TextStyle(
                          color: available > 0 ? const Color(0xFFF59E0B) : Colors.white24)),
                  style: TextButton.styleFrom(
                    backgroundColor: available > 0
                        ? const Color(0xFFF59E0B).withOpacity(0.1)
                        : Colors.white.withOpacity(0.03),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => creatorController.filteredCreators.length;

  @override
  int get selectedRowCount => 0;

  Future<void> _showReleaseDialog(
      BuildContext context,
      CreatorController creatorController,
      Creator creator,
      double available) async {
    final maxAmount = double.parse(available.toStringAsFixed(2));
    final amountController =
        TextEditingController(text: maxAmount.toStringAsFixed(2));
    final noteController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) {
        bool releasing = false;
        String? amountError;
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.payments_rounded, color: Color(0xFFF59E0B), size: 28),
                SizedBox(width: 12),
                Text(
                  'Release Payment',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator: ${creator.name ?? 'N/A'}   •   Available: ₹${maxAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w700),
                  onChanged: (_) => setState(() => amountError = null),
                  decoration: InputDecoration(
                    labelText: 'Amount to Release (₹)',
                    labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                    errorText: amountError,
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Note (e.g. UPI transfer, bank ref)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.note_rounded, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ Make sure you have physically transferred this amount before confirming.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: releasing ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                onPressed: releasing
                    ? null
                    : () async {
                        final parsed =
                            double.tryParse(amountController.text.trim());
                        if (parsed == null || parsed <= 0) {
                          setState(() => amountError = 'Enter a valid amount');
                          return;
                        }
                        if (parsed > maxAmount) {
                          setState(() => amountError =
                              'Cannot exceed available ₹${maxAmount.toStringAsFixed(2)}');
                          return;
                        }
                        setState(() => releasing = true);
                        final error = await creatorController.releasePayment(
                          creatorId: creator.id,
                          creatorName: creator.name ?? '',
                          amount: parsed,
                          note: noteController.text.trim(),
                        );
                        // Pop BEFORE dispose — TextField must be gone first
                        Navigator.of(ctx).pop();
                        if (error == null) {
                          // Refresh from Firestore to keep data accurate
                          creatorController.fetchReleasedAmounts();
                          Get.snackbar(
                            'Payment Released',
                            '₹${parsed.toStringAsFixed(2)} released for ${creator.name}',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 4),
                          );
                        } else {
                          Get.snackbar(
                            'Firebase Error',
                            error,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 8),
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                icon: releasing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(releasing ? 'Saving...' : 'Confirm Release'),
              ),
            ],
          );
        });
      },
    );
    // Safe to dispose after dialog is fully closed
    amountController.dispose();
    noteController.dispose();
  }

  void _showDeleteDialog(
      BuildContext context, CreatorController creatorController, Creator creator) {
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
                'Delete Creator',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${creator.name}? This action cannot be undone.',
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
                creatorController.deleteCreator(creator.id);
                Navigator.of(context).pop();
                Get.snackbar(
                  'Success',
                  'Creator deleted successfully!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
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
}
