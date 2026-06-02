import 'package:admin/screens/dashboard/components/banner.dart';
import 'package:admin/screens/dashboard/components/constraints.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'video_ads_tab.dart';

class AdvertisementPage extends StatefulWidget {
  const AdvertisementPage({Key? key}) : super(key: key);

  @override
  State<AdvertisementPage> createState() => _AdvertisementPageState();
}

class _AdvertisementPageState extends State<AdvertisementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showBannerStatusSnackbar = false;

  // Banner Tab Related Variables (Passed to BannerTab)
  bool _isLoadingBanners = true;
  List<Map<String, dynamic>> _existingBanners = [];

  // Video Ad Tab Related Variables (Passed to VideoAdsTab)
  List<Map<String, dynamic>> _existingVideoAds = [];
  bool _isLoadingVideoAds = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    //Load Data from firebase
    await _loadBanners();
    await _loadVideoAds();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    // Logic For Banner Loading
    // Call the loading logic from banner_tab.dart
    BannerTab.loadBanners(setState, context, (isLoading) {
      _isLoadingBanners = isLoading;
    }, (banners) {
      _existingBanners = banners;
    });
  }

  Future<void> _loadVideoAds() async {
    // Logic For Video Ads Loading
    VideoAdsTab.loadVideoAds(setState, context, (isLoading) {
      _isLoadingVideoAds = isLoading;
    }, (videoAds) {
      _existingVideoAds = videoAds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: primaryBackgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           Expanded(
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advertisement Management',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold, color: Colors.white) ??
                          const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: defaultPadding),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Banners'),
                        Tab(text: 'Video Ads'),
                      ],
                      indicatorColor: Colors.blue,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorWeight: 3,
                    ),
                    const SizedBox(height: defaultPadding),
                    Expanded(
                      child: Card(
                        color: secondaryBackgroundColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(defaultPadding),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Banners Tab Content
                              BannerTab(
                                existingBanners: _existingBanners,
                                isLoadingBanners: _isLoadingBanners,
                                onBannersChanged: (newBanners) {
                                  setState(() {
                                    _existingBanners = newBanners;
                                  });
                                },
                                onIsLoadingChanged: (isLoading) {
                                  setState(() {
                                    _isLoadingBanners = isLoading;
                                  });
                                },
                                showBannerStatusSnackbar:
                                    _showBannerStatusSnackbar,
                                onShowBannerStatusSnackbarChanged: (value) {
                                  setState(() {
                                    _showBannerStatusSnackbar = value;
                                  });
                                },
                              ),
                              // Video Ads Tab Content
                              VideoAdsTab(
                                existingVideoAds: _existingVideoAds,
                                isLoadingVideoAds: _isLoadingVideoAds,
                                onVideoAdsChanged: (newVideoAds) {
                                  setState(() {
                                    _existingVideoAds = newVideoAds;
                                  });
                                },
                                onIsLoadingChanged: (isLoading) {
                                  setState(() {
                                    _isLoadingVideoAds = isLoading;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _showBannerStatusSnackbar
          ? Container(
              height: 50,
              color: Colors.grey[800],
              child: const Center(
                child: Text(
                  "Banner status updated",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          : null,
    );
  }
}