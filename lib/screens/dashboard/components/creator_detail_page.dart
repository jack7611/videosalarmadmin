import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/models/Creator.dart';
import 'package:admin/models/Movies.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class CreatorDetailPage extends StatefulWidget {
  final Creator creator;
  const CreatorDetailPage({Key? key, required this.creator}) : super(key: key);

  @override
  State<CreatorDetailPage> createState() => _CreatorDetailPageState();
}

class _CreatorDetailPageState extends State<CreatorDetailPage> {
  bool _loading = true;
  List<Movie> _movies = [];
  double _ratePerHour = 50.0;
  double _totalReleased = 0.0;
  List<Map<String, dynamic>> _paymentHistory = [];

  // ── derived stats ──────────────────────────────────────────────────────────
  int get _totalMovies => _movies.length;
  int get _totalViews => _movies.fold(0, (s, m) => s + m.viewsCount);
  int get _totalWatchSeconds =>
      _movies.fold(0, (s, m) => s + m.watchSecondsCount);
  double get _totalEarnings => (_totalWatchSeconds / 3600.0) * _ratePerHour;
  double get _availableWallet =>
      (_totalEarnings - _totalReleased).clamp(0.0, double.infinity);

  double _movieEarnings(Movie m) =>
      (m.watchSecondsCount / 3600.0) * _ratePerHour;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch movies and rate together — these must succeed
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('newvideos')
            .where('creatorId', isEqualTo: widget.creator.id)
            .get(),
        FirebaseFirestore.instance
            .collection('settings')
            .doc('earnings')
            .get(),
      ]);

      final movieSnap = results[0] as QuerySnapshot;
      final rateDoc = results[1] as DocumentSnapshot;

      final movies = movieSnap.docs
          .map((d) =>
              Movie.fromFirestore(d.id, d.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.watchSecondsCount.compareTo(a.watchSecondsCount));

      final rateRaw =
          (rateDoc.data() as Map<String, dynamic>?)?['ratePerWatchHour'];

      setState(() {
        _movies = movies;
        _ratePerHour = rateRaw != null ? (rateRaw as num).toDouble() : 50.0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }

    // Fetch payments separately — failure here must NOT block movie data
    try {
      final paymentsSnap = await FirebaseFirestore.instance
          .collection('creator_payments')
          .where('creatorId', isEqualTo: widget.creator.id)
          .get();

      final payments = paymentsSnap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList()
        ..sort((a, b) {
          final aTs = a['releasedAt'] as Timestamp?;
          final bTs = b['releasedAt'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

      final released = payments.fold<double>(
          0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

      if (mounted) {
        setState(() {
          _paymentHistory = payments;
          _totalReleased = released;
        });
      }
    } catch (_) {}
  }

  Future<void> _showReleaseDialog() async {
    if (_availableWallet <= 0) return;
    final maxAmount = double.parse(_availableWallet.toStringAsFixed(2));
    final amountController = TextEditingController(text: maxAmount.toStringAsFixed(2));
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        bool releasing = false;
        String? amountError;
        return StatefulBuilder(builder: (ctx, setS) {

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.payments_rounded, color: Color(0xFFF59E0B), size: 28),
                SizedBox(width: 12),
                Text('Release Payment',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available: ₹${maxAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w700),
                  onChanged: (_) => setS(() => amountError = null),
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
                    hintText: 'Note (UPI ref, bank transfer ID, etc.)',
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
                  '⚠️ Confirm only after you have physically transferred the amount.',
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
                        final parsed = double.tryParse(amountController.text.trim());
                        if (parsed == null || parsed <= 0) {
                          setS(() => amountError = 'Enter a valid amount');
                          return;
                        }
                        if (parsed > maxAmount) {
                          setS(() => amountError =
                              'Cannot exceed available ₹${maxAmount.toStringAsFixed(2)}');
                          return;
                        }
                        setS(() => releasing = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('creator_payments')
                              .add({
                            'creatorId': widget.creator.id,
                            'creatorName': widget.creator.name ?? '',
                            'amount': parsed,
                            'note': noteController.text.trim(),
                            'releasedAt': FieldValue.serverTimestamp(),
                          });
                          // Pop BEFORE dispose — TextField must be gone first
                          Navigator.of(ctx).pop();
                          // Sync the shared controller so the list page wallet updates too
                          try {
                            final ctrl = Get.find<CreatorController>();
                            final prev = ctrl.creatorReleasedAmounts[widget.creator.id] ?? 0.0;
                            ctrl.creatorReleasedAmounts[widget.creator.id] = prev + parsed;
                            ctrl.releaseVersion.value++;
                          } catch (_) {}
                          if (mounted) {
                            setState(() => _loading = true);
                            _fetchData();
                          }
                          Get.snackbar(
                            'Payment Released',
                            '₹${parsed.toStringAsFixed(2)} released for ${widget.creator.name}',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } catch (e) {
                          setS(() => releasing = false);
                          Get.snackbar('Firebase Error', e.toString(),
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                              duration: const Duration(seconds: 8),
                              margin: const EdgeInsets.all(16));
                        }
                      },
                icon: releasing
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
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

  String _formatWatchTime(int secs) {
    if (secs <= 0) return '0s';
    if (secs < 60) return '${secs}s';
    if (secs < 3600) return '${secs ~/ 60}m ${secs % 60}s';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  String _formatDate(DateTime? dt) =>
      dt != null ? DateFormat('dd MMM yyyy').format(dt) : 'N/A';

  String _rupees(double v) =>
      '₹${v.toStringAsFixed(v >= 1 ? 0 : 2)}';

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final creator = widget.creator;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(children: [
          _avatar(creator.name, 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.name ?? 'Creator',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  creator.companyName?.isNotEmpty == true
                      ? creator.companyName!
                      : 'No Company',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ]),
        actions: [
          if (!_loading && _availableWallet > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: _showReleaseDialog,
                icon: const Icon(Icons.payments_rounded, size: 18),
                label: Text('Release ₹${_availableWallet.toStringAsFixed(0)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              setState(() => _loading = true);
              _fetchData();
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCreatorInfo(creator),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 18),
                  _buildWalletRow(),
                  const SizedBox(height: 28),
                  _buildMoviesSection(),
                  const SizedBox(height: 28),
                  _buildPaymentHistory(),
                ],
              ),
            ),
    );
  }

  // ── Creator info card ─────────────────────────────────────────────────────

  Widget _buildCreatorInfo(Creator creator) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(creator.name, 64),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    creator.name ?? 'N/A',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 12),
                  _statusBadge(creator.active ?? true),
                ]),
                if (creator.companyName?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(creator.companyName!,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 14)),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                    _infoChip(
                        Icons.email_rounded, creator.email ?? 'N/A'),
                    _infoChip(
                        Icons.phone_rounded, creator.phoneNo ?? 'N/A'),
                    _infoChip(Icons.calendar_today_rounded,
                        'Joined ${_formatDate(creator.createdAt)}'),
                    _infoChip(Icons.monetization_on_rounded,
                        'Rate: ${_rupees(_ratePerHour)}/hr'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary stats row ─────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = (constraints.maxWidth - 18 * 3) / 4;
      return Row(children: [
        _statCard('Total Movies', '$_totalMovies',
            Icons.movie_rounded, const Color(0xFF6366F1), w),
        const SizedBox(width: 18),
        _statCard('Total Views', '$_totalViews',
            Icons.visibility_rounded, const Color(0xFF10B981), w),
        const SizedBox(width: 18),
        _statCard(
            'Total Watch Hours',
            _formatWatchTime(_totalWatchSeconds),
            Icons.access_time_rounded,
            const Color(0xFFF59E0B),
            w),
        const SizedBox(width: 18),
        _statCard(
            'Total Earnings',
            _rupees(_totalEarnings),
            Icons.account_balance_wallet_rounded,
            const Color(0xFFEC4899),
            w),
      ]);
    });
  }

  Widget _buildWalletRow() {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = (constraints.maxWidth - 18) / 2;
      return Row(children: [
        _statCard(
            'Total Released',
            _rupees(_totalReleased),
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
            w),
        const SizedBox(width: 18),
        _statCard(
            'Available Wallet',
            _rupees(_availableWallet),
            Icons.account_balance_rounded,
            const Color(0xFFF59E0B),
            w),
      ]);
    });
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 14),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  // ── Movies section ────────────────────────────────────────────────────────

  Widget _buildMoviesSection() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.video_library_rounded,
                    color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 14),
              const Text('Movies & Earnings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  '${_movies.length} movies',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 13),
                ),
              ),
            ]),
          ),
          // Column headers
          if (_movies.isNotEmpty)
            Container(
              color: const Color(0xFF0F0F0F),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
              child: Row(children: [
                const SizedBox(width: 56),
                const Expanded(
                    flex: 3,
                    child: Text('Title',
                        style: _headerStyle)),
                const Expanded(
                    child: Text('Views',
                        style: _headerStyle,
                        textAlign: TextAlign.center)),
                const Expanded(
                    child: Text('Watch Time',
                        style: _headerStyle,
                        textAlign: TextAlign.center)),
                const Expanded(
                    child: Text('Earnings',
                        style: _headerStyle,
                        textAlign: TextAlign.center)),
                const Expanded(
                    child: Text('Category',
                        style: _headerStyle,
                        textAlign: TextAlign.center)),
              ]),
            ),
          // Movie rows
          _movies.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(
                    child: Column(children: [
                      Icon(Icons.movie_creation_outlined,
                          size: 48,
                          color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      const Text('No movies uploaded yet',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 14)),
                    ]),
                  ),
                )
              : Column(
                  children: List.generate(_movies.length, (i) {
                    final movie = _movies[i];
                    return _buildMovieRow(movie, i);
                  }),
                ),
          // Totals footer
          if (_movies.isNotEmpty) _buildTotalsFooter(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMovieRow(Movie movie, int index) {
    final earnings = _movieEarnings(movie);
    final watchTime = _formatWatchTime(movie.watchSecondsCount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: index.isEven
            ? Colors.transparent
            : Colors.white.withOpacity(0.02),
        border: const Border(
            top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: movie.thumbnailUrl?.isNotEmpty == true
                ? Image.network(
                    movie.thumbnailUrl!,
                    width: 48,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                  )
                : _thumbPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Title + year
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.titleText.isNotEmpty
                      ? movie.titleText
                      : 'Untitled',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (movie.yearText.isNotEmpty)
                  Text(movie.yearText,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          // Views
          Expanded(
            child: Text(
              '${movie.viewsCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13),
            ),
          ),
          // Watch time
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  watchTime,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // Earnings
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: earnings > 0
                    ? Colors.green.withOpacity(0.12)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _rupees(earnings),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: earnings > 0
                        ? Colors.greenAccent
                        : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // Category
          Expanded(
            child: Text(
              movie.categoryText.isNotEmpty
                  ? movie.categoryText
                  : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsFooter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(children: [
        const SizedBox(width: 60),
        Expanded(
          flex: 3,
          child: Text(
            'TOTALS  (${_totalMovies} movies)',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
        ),
        Expanded(
          child: Text(
            '$_totalViews',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            _formatWatchTime(_totalWatchSeconds),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.amber,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            _rupees(_totalEarnings),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.w900),
          ),
        ),
        const Expanded(child: SizedBox()),
      ]),
    );
  }

  // ── Payment history ───────────────────────────────────────────────────────

  Widget _buildPaymentHistory() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 14),
              const Text('Payment Release History',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  '${_paymentHistory.length} releases',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ]),
          ),
          if (_paymentHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Text('No payments released yet.',
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
            )
          else
            ...List.generate(_paymentHistory.length, (i) {
              final p = _paymentHistory[i];
              final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final note = p['note'] as String? ?? '';
              final ts = p['releasedAt'] as Timestamp?;
              final dateStr = ts != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate().toLocal())
                  : 'N/A';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.transparent : Colors.white.withOpacity(0.02),
                  border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Color(0xFFF59E0B), size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '₹${amount.toStringAsFixed(0)} released',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      if (note.isNotEmpty)
                        Text(note,
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ),
                  Text(dateStr,
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ]),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _avatar(String? name, double size) {
    final initial =
        (name?.isNotEmpty == true) ? name![0].toUpperCase() : 'C';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: Text(initial,
            style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: active ? Colors.green : Colors.red, width: 1),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
            color: active ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.white38),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 13)),
    ]);
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 48,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.movie_rounded,
          size: 16, color: Colors.white24),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: Colors.white54,
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.3,
);
