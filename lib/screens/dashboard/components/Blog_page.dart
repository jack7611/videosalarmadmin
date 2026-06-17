import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/screens/dashboard/components/blog_detail.dart';
import 'package:admin/screens/dashboard/components/edit_blog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

const Color _bg = Color(0xFF1A202C);
const Color _card = Color(0xFF2D3748);
const Color _primary = Color(0xFFF7FAFC);
const Color _secondary = Color(0xFFA0AEC0);
const Color _subtle = Color(0xFF718096);
const Color _accent = Color(0xFF6366F1);

class BlogPage extends StatelessWidget {
  const BlogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BlogController blogController = Get.put(BlogController());
    final FirebaseUploader uploader = FirebaseUploader();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Content Management',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24, color: Colors.white),
        ),
        backgroundColor: _bg,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showUploadMediaDialog(context, uploader),
              icon: const Icon(Icons.movie_creation_outlined, size: 18, color: Colors.white),
              label: const Text('Upload Media', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF805AD5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _showUploadDialog(context, uploader),
              icon: const Icon(Icons.upload, size: 18, color: Colors.white),
              label: const Text('Upload Blogs', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF38A169),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => Get.toNamed('/Addblog'),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('Add New Blog', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: _accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Obx(() {
          if (blogController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
              ),
            );
          }
          if (blogController.error.isNotEmpty) {
            return Center(
              child: Text(blogController.error.value,
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
            );
          }

          final blogs = blogController.blogData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Row(
                children: [
                  _summaryCard(
                    icon: Icons.article_rounded,
                    title: 'Total Blogs',
                    value: blogs.length.toString(),
                    color: const Color(0xFF4299E1),
                  ),
                  const SizedBox(width: 16),
                  _summaryCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Authors',
                    value: blogs.map((b) => b['author']).toSet().length.toString(),
                    color: const Color(0xFF48BB78),
                  ),
                  const SizedBox(width: 16),
                  _summaryCard(
                    icon: Icons.schedule_rounded,
                    title: 'Latest Blog',
                    value: blogs.isNotEmpty && blogs.first['publishedAt'] != null
                        ? DateFormat('d MMM yyyy')
                            .format(DateTime.parse(blogs.first['publishedAt']))
                        : '—',
                    color: const Color(0xFFED8936),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Table
              Expanded(
                child: blogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.article_outlined, size: 64, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text('No blogs found.',
                                style: TextStyle(fontSize: 18, color: _secondary)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Get.toNamed('/Addblog'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Blog'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _BlogTable(blogData: blogs),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: _secondary)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: _primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, FirebaseUploader uploader) {
    showDialog(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Upload Initial Blogs',
        message: 'Are you sure you want to upload the initial 3 blog posts to Firebase? This may create duplicates if they already exist.',
        onConfirm: () => uploader.storeBlogsInFirebase(context),
      ),
    );
  }

  void _showUploadMediaDialog(BuildContext context, FirebaseUploader uploader) {
    showDialog(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: 'Upload Initial Media',
        message: 'Are you sure you want to upload the initial media content (movies and songs) to Firebase? This will store them in the \'videos\' collection.',
        onConfirm: () => uploader.storeMediaInFirebase(context),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  const _ConfirmDialog({required this.title, required this.message, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(color: _primary, fontWeight: FontWeight.w700)),
      content: Text(message, style: const TextStyle(color: _secondary, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: _secondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class _BlogTable extends StatelessWidget {
  final List<Map<String, dynamic>> blogData;
  const _BlogTable({required this.blogData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                const Icon(Icons.article_rounded, color: _secondary, size: 20),
                const SizedBox(width: 8),
                const Text('Blog Posts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                const Spacer(),
                Text('${blogData.length} total',
                    style: const TextStyle(color: _subtle, fontSize: 13)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowMaxHeight: 80,
                  columnSpacing: 24,
                  headingRowColor: MaterialStateProperty.resolveWith((_) => const Color(0xFF1A202C)),
                  headingRowHeight: 52,
                  columns: const [
                    DataColumn(label: Text('Author', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Title', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                    DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                  ],
                  rows: blogData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final blog = entry.value;
                    return DataRow(
                      color: MaterialStateProperty.resolveWith((_) =>
                          index.isEven ? _card : const Color(0xFF252D3D)),
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              blog['author'] ?? 'N/A',
                              style: const TextStyle(color: _accent, fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              blog['title_en'] ?? blog['title'] ?? 'No Title',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _primary, fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 13, color: _subtle),
                              const SizedBox(width: 6),
                              Text(
                                blog['publishedAt'] != null
                                    ? DateFormat('d MMM yy').format(DateTime.parse(blog['publishedAt']))
                                    : 'N/A',
                                style: const TextStyle(color: _secondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 280,
                            child: Text(
                              blog['description_en'] ?? blog['description'] ?? 'No Description',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _secondary, fontSize: 13),
                            ),
                          ),
                        ),
                        DataCell(
                          TextButton.icon(
                            onPressed: () {
                              final url = blog['urlToImage'];
                              if (url != null && url.isNotEmpty) {
                                html.window.open(url, '_blank');
                              }
                            },
                            icon: const Icon(Icons.image_outlined, size: 15),
                            label: const Text('View'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4299E1),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _actionBtn(
                                icon: Icons.visibility_outlined,
                                color: const Color(0xFF4299E1),
                                tooltip: 'View Details',
                                onTap: () => Get.to(() => BlogDetailPage(blogId: blog['id'])),
                              ),
                              const SizedBox(width: 4),
                              _actionBtn(
                                icon: Icons.edit_outlined,
                                color: const Color(0xFFED8936),
                                tooltip: 'Edit Blog',
                                onTap: () => Get.to(() => EditBlogPage(blogId: blog['id'])),
                              ),
                              const SizedBox(width: 4),
                              _actionBtn(
                                icon: Icons.delete_outline,
                                color: const Color(0xFFE53E3E),
                                tooltip: 'Delete Blog',
                                onTap: () => _showDeleteDialog(context, blog),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> blog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[400]),
            const SizedBox(width: 8),
            const Text('Delete Blog', style: TextStyle(color: _primary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${blog['title_en'] ?? blog['title']}'? This action cannot be undone.",
          style: const TextStyle(color: _secondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: _secondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final BlogController blogController = Get.find();
              blogController.deleteBlog(blog['id']);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class FirebaseUploader {
  final List<Map<String, dynamic>> initialMediaContent = [
{
  "category": {
    "en": "Movie",
    "hi": "फ़िल्म"
  },
  "cbfc": {
    "en": "U",
    "hi": "यू"
  },
  "createdAt": "2025-08-15T00:00:00+05:30",
  "description": {
    "en": "Shedding light on Uttarakhand's lesser-known culinary paradise, Meethi Maa Ku Aashriwad celebrates the state's rich food heritage, weaving its diverse and nutrient-rich traditions into a narrative for national and international recognition.",
    "hi": "उत्तराखंड के कम ज्ञात पाक स्वर्ग पर प्रकाश डालते हुए, 'मीठी मां कू आशीर्वाद' राज्य की समृद्ध खाद्य धरोहर का उत्सव मनाती है, इसकी विविध और पोषक परंपराओं को राष्ट्रीय और अंतरराष्ट्रीय पहचान के लिए एक कथा में पिरोती है।"
  },
  "director": {
    "en": "Kanta Prasad",
    "hi": "कांत प्रसाद"
  },
  "duration": {
    "en": "2h 32m",
    "hi": "2 घंटे 32 मिनट"
  },
  "myList": false,
  "releaseDate": "2025-08-15T00:00:00+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "starcast": {
    "en": "Megha Khugshal, Mohit Ghildiyal, Sristi Rawat and Jasskaran Singh",
    "hi": "मेघा खुगशल, मोहित घिल्डियाल, सृष्टि रावत और जस्सकरण सिंह"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/meethi.jpg?alt=media&token=603c1ee4-6cd3-4b82-ac4e-0d9838c83028",
  "title": {
    "en": "Meethi Maa Ku Aashirwad",
    "hi": "मीठी मां कू आशीर्वाद"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/81249cce-1340-4922-8c47-7f2308162892",
  "views": 1506
},
   {
  "category": {
    "en": "Movie",
    "hi": "फ़िल्म"
  },
  "cbfc": {
    "en": "U",
    "hi": "यू"
  },
  "createdAt": "2025-06-28T00:00:00+05:30",
  "description": {
    "en": "A brave village girl turned sub-inspector, Sangeeta faces tragedy and loss, but fights back with resilience to rebuild her life and chase new dreams.",
    "hi": "एक साहसी गाँव की लड़की जो सब-इंस्पेक्टर बनी, संगीता दुख और हानि का सामना करती है, लेकिन अपनी दृढ़ता से जीवन को फिर से संवारती है और नए सपनों का पीछा करती है।"
  },
  "director": {
    "en": "Ashok Chauhan",
    "hi": "अशोक चौहान"
  },
  "duration": {
    "en": "2h 3m",
    "hi": "2 घंटे 3 मिनट"
  },
  "myList": false,
  "releaseDate": "2025-06-28T00:00:00+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "starcast": {
    "en": "Sanjay Siludi, Kanika Bahuguna, Rajesh Malguri, and Rajesh Gaur",
    "hi": "संजय सिलुड़ी, कनिका बहुगुणा, राजेश मालगुरी और राजेश गौड़"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/images%2FRatbyan%20Final%20Thumbnail.jpg?alt=media&token=3c492920-c656-476a-bebd-bb170e4dceaf",
  "title": {
    "en": "Ratbyan",
    "hi": "रातब्यान"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/9b0a08fd-7732-42c1-9f74-1eae8a519b17",
  "views": 2810
},
    {
  "category": {
    "en": "Songs",
    "hi": "गीत"
  },
  "cbfc": {
    "en": "U",
    "hi": "यू"
  },
  "createdAt": "2025-07-12T19:32:55+05:30",
  "description": {
    "en": "Ratbyan Title Track",
    "hi": "रातब्यान शीर्षक गीत"
  },
  "director": {
    "en": "Ashok Chauhan",
    "hi": "अशोक चौहान"
  },
  "duration": {
    "en": "7m",
    "hi": "7 मिनट"
  },
  "myList": false,
  "releaseDate": "2025-07-12T19:33:55+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "starcast": {
    "en": "Sanjay Siludi, Kanika Bahuguna, Rajesh Malguri, and Rajesh Gaur",
    "hi": "संजय सिलुड़ी, कनिका बहुगुणा, राजेश मालगुरी और राजेश गौड़"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/Ratbyan%20Song%20Thumbnail.jpeg?alt=media&token=a684b547-8f5a-4c5b-b25c-a58f019585a0",
  "title": {
    "en": "Ratbyan Song",
    "hi": "रातब्यान गीत"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/5cb3e86e-9f44-4de9-b9c2-f9b1a4476ad1",
  "views": 879
},
   {
  "category": {
    "en": "Songs",
    "hi": "गीत"
  },
  "cbfc": {
    "en": "U/A",
    "hi": "यू/ए"
  },
  "createdAt": "2025-04-16T17:24:04+05:30",
  "description": {
    "en": "Shree Shivay Namastubhyam With Lyrics | Swastika Mishra",
    "hi": "श्री शिवाय नमस्तुभ्यं | गीत के बोल सहित | स्वस्तिका मिश्रा"
  },
  "duration": {
    "en": "4m",
    "hi": "4 मिनट"
  },
  "myList": false,
  "releaseDate": "2025-02-11T12:00:00+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/1751263521648.jpg?alt=media&token=eb641b32-d91f-4f55-8125-e51c8f8c444a",
  "title": {
    "en": "Shri Shivay Namstubhyam",
    "hi": "श्री शिवाय नमस्तुभ्यं"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/0cf841f6-248a-4ff9-af80-fbc63b367cb3",
  "views": 1388
},
{
  "category": {
    "en": "Movie",
    "hi": "फ़िल्म"
  },
  "cbfc": {
    "en": "U/A 13+",
    "hi": "यू/ए 13+"
  },
  "createdAt": "2025-03-31T17:23:02+05:30",
  "description": {
    "en": "A young soldier defies tradition, urging his father to let his widowed wife remarry. Despite community disapproval, she finds love and weds again.",
    "hi": "एक युवा सैनिक परंपरा को तोड़ते हुए अपने पिता से आग्रह करता है कि वह अपनी विधवा पत्नी को पुनर्विवाह की अनुमति दें। समाज की अस्वीकृति के बावजूद, वह प्रेम पाती है और फिर से विवाह करती है।"
  },
  "director": {
    "en": "Debu Rawat",
    "hi": "देबू रावत"
  },
  "duration": {
    "en": "2h 19m",
    "hi": "2 घंटे 19 मिनट"
  },
  "myList": false,
  "releaseDate": "2025-03-31T12:00:00+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "starcast": {
    "en": "Purushottam Jethudi, Poonam Lakhera, and Anuj Kandari",
    "hi": "पुरुषोत्तम जेठुड़ी, पूनम लखेड़ा और अनुज कंडारी"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/images%2FWhatsApp%20Image%202025-05-27%20at%202.40.36%20PM.jpeg?alt=media&token=c3d1d-89a7-44e8-b457-2f0ea60eda21",
  "title": {
    "en": "Shaheed",
    "hi": "शहीद"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/39546063-dbe7-456a-b005-614799a809e3",
  "views": 3147
},
   {
  "category": {
    "en": "Songs",
    "hi": "गीत"
  },
  "cbfc": {
    "en": "U/A 13+",
    "hi": "यू/ए 13+"
  },
  "createdAt": "2025-06-30T13:28:01+05:30",
  "description": {
    "en": "Thumka Song",
    "hi": "ठुमका गीत"
  },
  "director": {
    "en": "Debu Rawat",
    "hi": "देबू रावत"
  },
  "duration": {
    "en": "4:40m",
    "hi": "4 मिनट 40 सेकंड"
  },
  "myList": false,
  "releaseDate": "2025-06-03T16:00:00+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "starcast": {
    "en": "Purushottam Jethudi, Poonam Lakhera, and Anuj Kandari",
    "hi": "पुरुषोत्तम जेठुड़ी, पूनम लखेड़ा और अनुज कंडारी"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/images%2F4.png?alt=media&token=020d0527-8c5d-4a12-a490-4355e3f04c8e",
  "title": {
    "en": "Thumka Song",
    "hi": "ठुमका गीत"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/1ad511bc-712d-4eac-84c8-2d88f43344ff",
  "views": 1376
},
   {
  "category": {
    "en": "Songs",
    "hi": "गीत"
  },
  "cbfc": {
    "en": "U/A 13+",
    "hi": "यू/ए 13+"
  },
  "createdAt": "2025-06-30T13:28:26+05:30",
  "description": {
    "en": "Meru Supniu Song",
    "hi": "मेरु सुपन्यु गीत"
  },
  "director": {
    "en": "Debu Rawat",
    "hi": "देबू रावत"
  },
  "duration": {
    "en": "5:20m",
    "hi": "5 मिनट 20 सेकंड"
  },
  "myList": false,
  "releaseDate": "2025-06-03T16:00:00+05:30",
  "releaseYear": {
    "en": "2025",
    "hi": "२०२५"
  },
  "starcast": {
    "en": "Purushottam Jethudi, Poonam Lakhera, and Anuj Kandari",
    "hi": "पुरुषोत्तम जेठुड़ी, पूनम लखेड़ा और अनुज कंडारी"
  },
  "thumbnailUrl": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/images%2F5.png?alt=media&token=5f78a8de-f18b-4958-80fa-803070c436b0",
  "title": {
    "en": "Meru Supniu",
    "hi": "मेरु सुपन्यु"
  },
  "videoUrl": "https://iframe.mediadelivery.net/play/460348/8d2f5087-a2ea-4fdc-bea4-7b145a8119c1",
  "views": 1353
}
  ];

  final List<Map<String, dynamic>> blogs = [
    {
      "author": "Rahul",
      "title_en": "Why VideosAlarm is the App Every Uttarakhandi Needs",
      "title_hi": "वीडियोअलार्म: हर उत्तराखंडी के लिए जरूरी ऐप",
      "description_en": "VideosAlarm is more than an app; it's a celebration of Uttarakhand's culture through music and soon-to-be-launched video content.",
      "description_hi": "वीडियोअलार्म सिर्फ एक ऐप नहीं है; यह उत्तराखंड की संस्कृति का संगीत और जल्द लॉन्च होने वाले वीडियो कंटेंट के माध्यम से उत्सव है।",
      "content_en": "In today's fast-paced world, staying connected to your roots can be challenging. That's where VideosAlarm comes in – an app crafted to keep you close to the heart of Uttarakhand through its music and entertainment.",
      "content_hi": "आज की तेज़-तर्रार दुनिया में अपनी जड़ों से जुड़े रहना चुनौतीपूर्ण हो सकता है। यहीं पर वीडियोअलार्म आता है।",
      "publishedAt": "2024-10-25T13:38:07.479Z",
      "url": "https://en.wikipedia.org/wiki/Blog",
      "urlToImage": "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/blog%20images%2Fvideoalarm_logo.jpg?alt=media&token=10b68586-2ed1-4f98-8c43-6a95ce37a998",
      "source": {"id": "1", "name": "New Source"}
    },
  ];

  Future<void> storeMediaInFirebase(BuildContext context) async {
    final CollectionReference videoCollection =
        FirebaseFirestore.instance.collection('newvideos');
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var mediaData in initialMediaContent) {
      DocumentReference docRef = videoCollection.doc(mediaData['id']);
      batch.set(docRef, mediaData);
    }
    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully uploaded media content!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading media: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> storeBlogsInFirebase(BuildContext context) async {
    final CollectionReference blogCollection =
        FirebaseFirestore.instance.collection('blogsnew');
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var blogData in blogs) {
      DocumentReference docRef = blogCollection.doc();
      batch.set(docRef, blogData);
    }
    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully uploaded blogs!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading blogs: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
