import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/screens/dashboard/components/blog_detail.dart';
import 'package:admin/screens/dashboard/components/edit_blog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class BlogPage extends StatelessWidget {
  const BlogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    final BlogController blogController = Get.put(BlogController());
    final FirebaseUploader uploader = FirebaseUploader();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Row with Title and Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Content Management',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      // Upload Initial Media Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.movie_creation_outlined, color: Colors.white),
                        label: const Text("Upload Initial Media",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () => _showUploadMediaDialog(context, uploader),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Upload Initial Data Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text("Upload Initial Blogs",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () => _showUploadDialog(context, uploader),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Add New Blog Button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Add New Blog",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () => Get.toNamed('/Addblog'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Blog Table
              Obx(() {
                if (blogController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                } else if (blogController.error.isNotEmpty) {
                  return Center(child: Text(blogController.error.value, style: const TextStyle(color: Colors.red)));
                } else if (blogController.blogData.isEmpty){
                   return const Center(child: Text("No blogs found. Add a new one or upload initial data.", style: TextStyle(fontSize: 18)));
                }
                else {
                  return BlogTable(blogData: blogController.blogData);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, FirebaseUploader uploader) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Upload"),
          content: const Text(
              "Are you sure you want to upload the initial 3 blog posts to Firebase? This may create duplicates if they already exist."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Upload"),
              onPressed: () {
                Navigator.of(context).pop();
                uploader.storeBlogsInFirebase(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showUploadMediaDialog(BuildContext context, FirebaseUploader uploader) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Media Upload"),
          content: const Text(
              "Are you sure you want to upload the initial media content (movies and songs) to Firebase? This will store them in the 'videos' collection."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Upload"),
              onPressed: () {
                Navigator.of(context).pop();
                uploader.storeMediaInFirebase(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class BlogTable extends StatelessWidget {
  final List<Map<String, dynamic>> blogData;

  const BlogTable({Key? key, required this.blogData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: DataTable(
        dataRowMaxHeight: 80,
        headingRowColor: MaterialStateProperty.resolveWith(
            (states) => const Color.fromARGB(255, 14, 18, 21)),
        headingTextStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        columns: const [
          DataColumn(label: Text("Author")),
          DataColumn(label: Text("Title (English)")),
          DataColumn(label: Text("Date")),
          DataColumn(label: Text("Description (English)")),
          DataColumn(label: Text("Image")),
          DataColumn(label: Text("Actions")),
        ],
        rows: blogData.map((blog) {
          return DataRow(
            cells: [
              DataCell(Text(blog['author'] ?? 'N/A')),
              DataCell(
                SizedBox(
                  width: 200,
                  child: Text(
                    blog['title_en'] ?? 'No Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Text(
                  blog['publishedAt'] != null
                      ? DateFormat('d-MMM-yy').format(DateTime.parse(blog['publishedAt']))
                      : 'N/A',
                ),
              ),
              DataCell(
                SizedBox(
                  width: 300,
                  child: Text(
                    blog['description_en'] ?? 'No Description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                GestureDetector(
                  onTap: () => _launchImageURL(blog['urlToImage']),
                  child: const Text("View Image",
                      style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline)),
                ),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      tooltip: "View Details",
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () => Get.to(() => BlogDetailPage(blogId: blog['id'])),
                    ),
                    IconButton(
                      tooltip: "Edit Blog",
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => Get.to(() => EditBlogPage(blogId: blog['id'])),
                    ),
                    IconButton(
                      tooltip: "Delete Blog",
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(context, blog),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _launchImageURL(String? url) {
    if (url != null && url.isNotEmpty) {
      html.window.open(url, '_blank');
    }
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> blog) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Blog"),
          content: Text("Are you sure you want to delete '${blog['title_en']}'?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final BlogController blogController = Get.find();
                blogController.deleteBlog(blog['id']);
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class FirebaseUploader {
  
  // New list containing the movie and song data
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
    "en": "Shedding light on Uttarakhand’s lesser-known culinary paradise, Meethi Maa Ku Aashriwad celebrates the state’s rich food heritage, weaving its diverse and nutrient-rich traditions into a narrative for national and international recognition.",
    "hi": "उत्तराखंड के कम ज्ञात पाक स्वर्ग पर प्रकाश डालते हुए, ‘मीठी मां कू आशीर्वाद’ राज्य की समृद्ध खाद्य धरोहर का उत्सव मनाती है, इसकी विविध और पोषक परंपराओं को राष्ट्रीय और अंतरराष्ट्रीय पहचान के लिए एक कथा में पिरोती है।"
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
}
,
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
}
,
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
}
,
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

  // List of initial blog posts
  final List<Map<String, dynamic>> blogs = [
    {
      "author": "Rahul",
      "title_en": "Why VideosAlarm is the App Every Uttarakhandi Needs",
      "title_hi": "वीडियोअलार्म: हर उत्तराखंडी के लिए जरूरी ऐप",
      "description_en":
          "VideosAlarm is more than an app; it’s a celebration of Uttarakhand’s culture through music and soon-to-be-launched video content.",
      "description_hi":
          "वीडियोअलार्म सिर्फ एक ऐप नहीं है; यह उत्तराखंड की संस्कृति का संगीत और जल्द लॉन्च होने वाले वीडियो कंटेंट के माध्यम से उत्सव है।",
      "content_en":
          "In today’s fast-paced world, staying connected to your roots can be challenging. That’s where VideosAlarm comes in – an app crafted to keep you close to the heart of Uttarakhand through its music and entertainment. Why choose VideosAlarm? Connect to Culture: Immerse yourself in songs that reflect the traditions of Uttarakhand. Support Local Talent: By streaming music on VideosAlarm, you’re promoting regional artists and creators. Future-Ready: VideosAlarm is evolving to include web series, short films, and documentaries rooted in Uttarakhand’s essence. Whether you’re from the state or someone fascinated by its beauty and culture, VideosAlarm is your companion to experience it all. Download the app today and join the growing community that celebrates Uttarakhand’s vibrant spirit.",
      "content_hi":
          "आज की तेज़-तर्रार दुनिया में अपनी जड़ों से जुड़े रहना चुनौतीपूर्ण हो सकता है। यहीं पर वीडियोअलार्म आता है – एक ऐसा ऐप जिसे उत्तराखंड के दिल से जुड़े रहने के लिए संगीत और मनोरंजन के माध्यम से डिज़ाइन किया गया है। वीडियोअलार्म क्यों चुनें? संस्कृति से जुड़ें: उन गीतों में डूबें जो उत्तराखंड की परंपराओं को दर्शाते हैं। स्थानीय प्रतिभा का समर्थन करें: वीडियोअलार्म पर संगीत स्ट्रीम करके आप क्षेत्रीय कलाकारों और क्रिएटर्स को बढ़ावा दे रहे हैं। भविष्य के लिए तैयार: वीडियोअलार्म वेब सीरीज़, लघु फिल्में और डॉक्यूमेंट्रीज़ शामिल करने के लिए विकसित हो रहा है जो उत्तराखंड की आत्मा पर आधारित हैं। चाहे आप राज्य के हों या उसकी सुंदरता और संस्कृति से मोहित कोई व्यक्ति, वीडियोअलार्म आपके लिए इसे अनुभव करने का साथी है। आज ही ऐप डाउनलोड करें और उस बढ़ती हुई समुदाय में शामिल हों जो उत्तराखंड की जीवंत संस्कृति का जश्न मनाती है।",
      "publishedAt": "2024-10-25T13:38:07.479Z",
      "url":
          "https://en.wikipedia.org/wiki/Blog#:~:text=A%20blog%20(a%20truncation%20of,top%20of%20the%20web%20page.",
      "urlToImage":
          "https://firebasestorage.googleapis.com/v0/b/videoalarm-a0b26.appspot.com/o/blog%20images%2Fvideoalarm_logo.jpg?alt=media&token=10b68586-2ed1-4f98-8c43-6a95ce37a998",
      "source": {"id": "1", "name": "New Source"}
    },
    // ... other blogs
  ];

  /// NEW FUNCTION: Stores the initial movie and song data in Firestore.
  Future<void> storeMediaInFirebase(BuildContext context) async {
    final CollectionReference videoCollection =
        FirebaseFirestore.instance.collection('newvideos');

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var mediaData in initialMediaContent) {
      // Use the 'id' field from the JSON as the document ID
      DocumentReference docRef = videoCollection.doc(mediaData['id']);
      batch.set(docRef, mediaData);
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Successfully uploaded media content to Firebase!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading media: $e'),
            backgroundColor: Colors.red),
      );
    }
  }


  /// Stores the initial blog data in Firestore.
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
        const SnackBar(
            content: Text('Successfully uploaded blogs to Firebase!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading blogs: $e'),
            backgroundColor: Colors.red),
      );
    }
  }
}