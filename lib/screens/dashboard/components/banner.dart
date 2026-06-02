import 'dart:io';

import 'package:admin/screens/dashboard/components/constraints.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class BannerTab extends StatefulWidget {
  final List<Map<String, dynamic>> existingBanners;
  final bool isLoadingBanners;
  final Function(List<Map<String, dynamic>>) onBannersChanged;
  final Function(bool) onIsLoadingChanged;
  final Function(bool) onShowBannerStatusSnackbarChanged;

  const BannerTab({
    Key? key,
    required this.existingBanners,
    required this.isLoadingBanners,
    required this.onBannersChanged,
    required this.onIsLoadingChanged,
    required this.onShowBannerStatusSnackbarChanged,
    required bool showBannerStatusSnackbar,
  }) : super(key: key);

  @override
  State<BannerTab> createState() => _BannerTabState();

  // Static method to load banners
  static Future<void> loadBanners(
    StateSetter setState,
    BuildContext context,
    Function(bool) setIsLoading,
    Function(List<Map<String, dynamic>>) setBanners,
  ) async {
    setState(() {
      setIsLoading(true);
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection(bannerCollection)
              .orderBy('priority')
              .get(); // Order by priority

      List<Map<String, dynamic>> banners = querySnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id, // Store the document ID
              })
          .toList();

      setState(() {
        setBanners(banners);
        setIsLoading(false);
      });
    } catch (e) {
      print("Error loading banners: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load banners: $e')),
      );
      setState(() {
        setIsLoading(false);
      });
    }
  }
}

class _BannerTabState extends State<BannerTab> {
  File? _bannerImage;
  Uint8List? _bannerImageBytes;
  bool _isUploadingBanner = false;
  int _bannerPriority = 1; // Default priority

  @override
  void initState() {
    super.initState();
    // You might want to initialize the priority with the highest current priority + 1
    // Or simply keep the default as 1 and let the user manage it.
    // Example:
    //  _initializePriority();
  }

  Future<void> _initializePriority() async {
    // Fetch existing banners and determine the highest priority.
    // Set _bannerPriority to highestPriority + 1.
    // This is just a basic example and may need adjustment based on your needs.
    // You may want to handle cases where there are no existing banners.
    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection(bannerCollection)
              .orderBy('priority', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final highestPriority =
            querySnapshot.docs.first.data()['priority'] as int;
        setState(() {
          _bannerPriority = highestPriority + 1;
        });
      } else {
        // No banners exist yet, so start at 1
        _bannerPriority = 1;
      }
    } catch (e) {
      print("Error initializing priority: $e");
      // Handle the error, e.g., set _bannerPriority to a default value.
      _bannerPriority = 1;
    }
  }

  Future<void> _pickBannerImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (kIsWeb) {
        setState(() {
          _bannerImageBytes = file.bytes; // Store bytes for web
          _bannerImage = null;
        });
      } else {
        setState(() {
          _bannerImage = File(file.path!); // Store File for mobile
          _bannerImageBytes = null;
        });
      }
    }
  }

  Future<void> _uploadBanner() async {
    if ((_bannerImage == null && _bannerImageBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploadingBanner = true; // Start loading
    });

    try {
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child(bannerStorageFolder)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask uploadTask;
      if (kIsWeb) {
        // Web-specific upload using bytes
        uploadTask = storageRef.putData(_bannerImageBytes!);
      } else {
        // Mobile upload using File
        uploadTask = storageRef.putFile(_bannerImage!);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      final bannerData = {
        'imageUrl': imageUrl,
        'isActive': true, // Default value when uploading
        'timestamp': FieldValue.serverTimestamp(),
        'priority': _bannerPriority, // Add the priority
      };

      await FirebaseFirestore.instance
          .collection(bannerCollection)
          .add(bannerData);

      setState(() {
        _bannerImage = null;
        _bannerImageBytes = null;
        _bannerPriority = 1; // Reset priority to default
      });

      // reload The Data after Upload
      await BannerTab.loadBanners(setState, context, widget.onIsLoadingChanged,
          widget.onBannersChanged); // Call static method

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading banner: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload banner: $e')),
      );
    } finally {
      setState(() {
        _isUploadingBanner = false; // End loading
      });
    }
  }

  Future<void> _updateBannerStatus(String bannerId, bool newValue) async {
    try {
      await FirebaseFirestore.instance
          .collection(bannerCollection)
          .doc(bannerId)
          .update({'isActive': newValue});

      // Reload data after update
      await BannerTab.loadBanners(setState, context, widget.onIsLoadingChanged,
          widget.onBannersChanged); // Call static method

      setState(() {
        widget.onShowBannerStatusSnackbarChanged(true);
      });

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          widget.onShowBannerStatusSnackbarChanged(false);
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Banner status updated successfully!')),
      );
    } catch (e) {
      print("Error updating banner status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner status: $e')),
      );
    }
  }

  Future<void> _deleteBanner(String bannerId, String imageUrl) async {
    try {
      // 1. Delete the image from Firebase Storage
      final Reference storageRef =
          FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      // 2. Delete the document from Firestore
      await FirebaseFirestore.instance
          .collection(bannerCollection)
          .doc(bannerId)
          .delete();

      // 3. Refresh the banner list
      await BannerTab.loadBanners(setState, context, widget.onIsLoadingChanged,
          widget.onBannersChanged);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner deleted successfully!')),
      );
    } catch (e) {
      print("Error deleting banner: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete banner: $e')),
      );
    }
  }

  Future<void> _updateBannerPriority(String bannerId, int newPriority) async {
    try {
      await FirebaseFirestore.instance
          .collection(bannerCollection)
          .doc(bannerId)
          .update({'priority': newPriority});

      // Reload data after update
      await BannerTab.loadBanners(setState, context, widget.onIsLoadingChanged,
          widget.onBannersChanged); // Call static method

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Banner priority updated successfully!')),
      );
    } catch (e) {
      print("Error updating banner priority: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update banner priority: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SizedBox(
            width: constraints.maxWidth, // Make it responsive
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Increased overall padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Banners',
                    style: Theme.of(context).textTheme.h4?.copyWith(
                              // Larger heading
                              fontWeight: FontWeight.w700, // Bold
                              color: Colors.white, // White text
                            ) ??
                        const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  _buildUploadArea(),
                  const SizedBox(height: 48),
                  Text(
                    'Existing Banners',
                    style: Theme.of(context).textTheme.h5?.copyWith(
                              // Subheading
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ) ??
                        const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  widget.isLoadingBanners
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _buildExistingBannersGrid(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      //onTap: _pickBannerImage, // Removed onTap from here
      borderRadius: BorderRadius.circular(16), // More rounded corners
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // More rounded corners
          border: Border.all(
              color: Colors.grey.shade700, width: 2), // Softer border
          color: Colors.grey.shade800, // Darker background
        ),
        padding: const EdgeInsets.all(32), // Increased padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate,
                size: 80, color: Colors.grey.shade500), // New icon
            const SizedBox(height: 16),
            Text(
              'Click to select a new banner image', // Modified Text
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 20), // Softer color
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickBannerImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600, // Slightly lighter blue
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500), // Adjusted
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
              ),
              child: const Text("Select Banner Image"),
            ),
            if (_bannerImage != null || _bannerImageBytes != null) ...[
              const SizedBox(height: 32),
              TextFormField(
                initialValue: _bannerPriority.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Banner Priority',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _bannerPriority = int.tryParse(value) ?? 1;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isUploadingBanner ? null : _uploadBanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green.shade600, // Slightly lighter blue
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500), // Adjusted
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                ),
                child: _isUploadingBanner
                    ? const SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Upload Banner"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExistingBannersGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Disable GridView's scrolling
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: kIsWeb ? 3 : 1, // 3 columns on web, 1 on mobile
        crossAxisSpacing: 24, // Increased spacing
        mainAxisSpacing: 24, // Increased spacing
        childAspectRatio: kIsWeb ? 1.6 : 2.5, // Adjusted aspect ratio
      ),
      itemCount: widget.existingBanners.length,
      itemBuilder: (context, index) {
        final banner = widget.existingBanners[index];
        final bannerId = banner['id'];
        final isActive = banner['isActive'] ?? false;
        final imageUrl = banner['imageUrl'] as String? ?? '';
        final timestamp = banner['timestamp'] as Timestamp?;
        final priority =
            banner['priority'] as int? ?? 1; // Default to 1 if null

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800, // Darker card background
            borderRadius: BorderRadius.circular(16), // More rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Deeper shadow
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)), // More rounded corners
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.grey), // Different error icon
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey, size: 70), // New icon
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 18)), // New style
                        Switch(
                          value: isActive,
                          onChanged: (newValue) {
                            _updateBannerStatus(bannerId, newValue);
                          },
                          activeColor: Colors.blue.shade400, // New switch color
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: priority.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final newPriority = int.tryParse(value) ?? priority;
                        _updateBannerPriority(bannerId, newPriority);
                      },
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded: ${DateFormat('MMM d, yyyy – h:mm a').format(timestamp.toDate())}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 28), // New icon
                        onPressed: () {
                          if (imageUrl.isNotEmpty) {
                            _deleteBanner(bannerId, imageUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Image URL is missing!')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension on TextTheme { 
  get h4 => headlineMedium;

  get h5 => headlineMedium;
}
