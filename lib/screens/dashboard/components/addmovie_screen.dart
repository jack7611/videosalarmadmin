// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:admin/models/Movies.dart';
// import 'package:admin/controllers/movie_controller.dart';
// import 'package:admin/controllers/creator_controller.dart';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart'; // kIsWeb
// import 'package:intl/intl.dart';

// class AddmovieScreen extends StatefulWidget {
//   final Movie? movie;

//   const AddmovieScreen({Key? key, this.movie}) : super(key: key);

//   @override
//   State<AddmovieScreen> createState() => _AddmovieScreenState();
// }

// class _AddmovieScreenState extends State<AddmovieScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final MovieController _controller = Get.find<MovieController>();
//   final CreatorController _creatorController = Get.put(CreatorController());

//   // EN / HI controllers
//   final titleEn = TextEditingController();
//   final titleHi = TextEditingController();
//   final descEn = TextEditingController();
//   final descHi = TextEditingController();
//   final durationEn = TextEditingController();
//   final durationHi = TextEditingController();
//   final releaseYearEn = TextEditingController();
//   final releaseYearHi = TextEditingController();
//   String? categoryEn;
//   String? categoryHi;
//   final cbfcEn = TextEditingController();
//   final cbfcHi = TextEditingController();
//   final directorEn = TextEditingController();
//   final directorHi = TextEditingController();
//   final starcastEn = TextEditingController();
//   final starcastHi = TextEditingController();

//   // Single fields
//   Timestamp? createdAt;
//   Timestamp? releaseDate;
//   final createdAtController = TextEditingController();
//   final releaseDateController = TextEditingController();

//   //final videoUrl = TextEditingController();
//   final videoUrl2 = TextEditingController();
//   final thumbnailUrl = TextEditingController();
//   String _selectedCreatorId = 'admin';

//   bool _active = false;
//   bool _loading = false;
//   File? _thumbnailFile;
//   double _uploadProgress = 0.0;
//   bool _uploadingImage = false;
//   Uint8List? _thumbnailBytes; // web

//   @override
//   void initState() {
//     super.initState();

//     if (widget.movie != null) {
//       final m = widget.movie!;

//       // -------------------
//       // Dual-language fields
//       // -------------------
//       titleEn.text = m.title?['en'] ?? '';
//       titleHi.text = m.title?['hi'] ?? '';
//       descEn.text = m.description?['en'] ?? '';
//       descHi.text = m.description?['hi'] ?? '';
//       durationEn.text = m.duration?['en'] ?? '';
//       durationHi.text = m.duration?['hi'] ?? '';
//       releaseYearEn.text = m.releaseYear?['en'] ?? '';
//       releaseYearHi.text = m.releaseYear?['hi'] ?? '';
//       categoryEn = m.category?['en'] ?? '';
//       categoryHi = m.category?['hi'] ?? '';
//       cbfcEn.text = m.cbfc?['en'] ?? '';
//       cbfcHi.text = m.cbfc?['hi'] ?? '';
//       directorEn.text = m.director?['en'] ?? '';
//       directorHi.text = m.director?['hi'] ?? '';
//       starcastEn.text = m.starcast?['en'] ?? '';
//       starcastHi.text = m.starcast?['hi'] ?? '';

//       // -------------------
//       // Single fields
//       // -------------------
//       createdAt = m.createdAt;
//       if (createdAt != null) {
//         createdAtController.text =
//             DateFormat('yyyy-MM-dd HH:mm').format(createdAt!.toDate());
//       }
//       releaseDate = m.releaseDate;
//       if (releaseDate != null) {
//         releaseDateController.text =
//             DateFormat('yyyy-MM-dd HH:mm').format(releaseDate!.toDate());
//       }
//       videoUrl2.text = m.videoUrl2 ?? '';
//       thumbnailUrl.text = m.thumbnailUrl ?? '';
//       _selectedCreatorId = m.creatorId ?? 'admin';
//       _active = m.active;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.white, // ✅ WHITE BACKGROUND
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         width: 600,
//         color: Colors.white, // ✅ FORCE WHITE
//         padding: const EdgeInsets.all(24),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     _title(widget.movie != null ? 'Edit Movie' : 'Add Movie'),
//                     InkWell(
//                         onTap: () {
//                           Navigator.pop(context);
//                         },
//                         child: Icon(
//                           Icons.cancel_presentation,
//                           color: Colors.grey,
//                           size: 32,
//                         ))
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 _dualField("Title", titleEn, titleHi),
//                 _dualField("Description", descEn, descHi),
//                 _dualField("Duration", durationEn, durationHi),
//                 Text(
//                   'Ex : 1h 42m, 1 घंटे 42 मिनट ...',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 _dualField("Release Year", releaseYearEn, releaseYearHi),
//                 _dualDropdown(
//                   label: "Category",
//                   enValue: categoryEn,
//                   hiValue: categoryHi,
//                   onEnChanged: (val) {
//                     categoryEn = val;
//                   },
//                   onHiChanged: (val) {
//                     categoryHi = val;
//                   },
//                 ),
//                 _dualField("CBFC", cbfcEn, cbfcHi),
//                 Text(
//                   'Ex : U/A 13+, यू/ए 13+, ...',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 _dualField("Director", directorEn, directorHi),
//                 _dualField("Starcast", starcastEn, starcastHi),
//                 // GestureDetector(
//                 //   onTap: () async {
//                 //     final now = DateTime.now();
//                 //     final currentVal = createdAt?.toDate() ?? now;
//                 //     final pickedDate = await showDatePicker(
//                 //       context: context,
//                 //       initialDate: currentVal,
//                 //       firstDate: DateTime(2000),
//                 //       lastDate: DateTime(2100),
//                 //     );
//                 //     if (pickedDate != null) {
//                 //       final pickedTime = await showTimePicker(
//                 //         context: context,
//                 //         initialTime: TimeOfDay.fromDateTime(currentVal),
//                 //       );
//                 //       if (pickedTime != null) {
//                 //         final newDateTime = DateTime(
//                 //           pickedDate.year,
//                 //           pickedDate.month,
//                 //           pickedDate.day,
//                 //           pickedTime.hour,
//                 //           pickedTime.minute,
//                 //         );
//                 //         setState(() {
//                 //           createdAt = Timestamp.fromDate(newDateTime);
//                 //           createdAtController.text =
//                 //               DateFormat('yyyy-MM-dd HH:mm')
//                 //                   .format(newDateTime);
//                 //         });
//                 //       }
//                 //     }
//                 //   },
//                 //   child: AbsorbPointer(
//                 //     child: _field("Created At", createdAtController),
//                 //   ),
//                 // ),
//                 GestureDetector(
//                   onTap: () async {
//                     final now = DateTime.now();
//                     final currentVal = releaseDate?.toDate() ?? now;
//                     final pickedDate = await showDatePicker(
//                       context: context,
//                       initialDate: currentVal,
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime(2100),
//                     );
//                     if (pickedDate != null) {
//                       final pickedTime = await showTimePicker(
//                         context: context,
//                         initialTime: TimeOfDay.fromDateTime(currentVal),
//                       );
//                       if (pickedTime != null) {
//                         final newDateTime = DateTime(
//                           pickedDate.year,
//                           pickedDate.month,
//                           pickedDate.day,
//                           pickedTime.hour,
//                           pickedTime.minute,
//                         );
//                         setState(() {
//                           releaseDate = Timestamp.fromDate(newDateTime);
//                           releaseDateController.text =
//                               DateFormat('yyyy-MM-dd HH:mm')
//                                   .format(newDateTime);
//                         });
//                       }
//                     }
//                   },
//                   child: AbsorbPointer(
//                     child: _field("Release Date", releaseDateController),
//                   ),
//                 ),
//                 //_field("Views", views, isNumber: true),
//                 _field("Video URL", videoUrl2),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "Creator",
//                   style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Obx(() {
//                   if (_creatorController.isLoading.value) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   // Build items list: Admin + fetched creators
//                   List<DropdownMenuItem<String>> items = [
//                     const DropdownMenuItem(
//                       value: 'admin',
//                       child: Text('Admin'),
//                     ),
//                   ];

//                   items.addAll(_creatorController.creators.map((creator) {
//                     return DropdownMenuItem(
//                       value: creator.id,
//                       child: Text(creator.name ?? 'Unknown'),
//                     );
//                   }).toList());

//                   // Ensure selected value exists in logic, else default to admin
//                   // This fails safe if a creator was deleted
//                   if (!items.any((item) => item.value == _selectedCreatorId)) {
//                     _selectedCreatorId = 'admin';
//                   }

//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: _selectedCreatorId,
//                         isExpanded: true,
//                         dropdownColor: Colors.white,
//                         style: const TextStyle(color: Colors.black),
//                         items: items,
//                         onChanged: (val) =>
//                             setState(() => _selectedCreatorId = val ?? 'admin'),
//                       ),
//                     ),
//                   );
//                 }),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "Thumbnail",
//                   style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 GestureDetector(
//                   onTap: _pickThumbnail,
//                   child: Container(
//                     height: 150,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.black),
//                       borderRadius: BorderRadius.circular(8),
//                       image: kIsWeb
//                           ? (_thumbnailBytes != null
//                               ? DecorationImage(
//                                   image: MemoryImage(_thumbnailBytes!),
//                                   fit: BoxFit.cover,
//                                 )
//                               : (thumbnailUrl.text.isNotEmpty
//                                   ? DecorationImage(
//                                       image: NetworkImage(thumbnailUrl.text),
//                                       fit: BoxFit.cover,
//                                     )
//                                   : null))
//                           : (_thumbnailFile != null
//                               ? DecorationImage(
//                                   image: FileImage(_thumbnailFile!),
//                                   fit: BoxFit.cover,
//                                 )
//                               : (thumbnailUrl.text.isNotEmpty
//                                   ? DecorationImage(
//                                       image: NetworkImage(thumbnailUrl.text),
//                                       fit: BoxFit.cover,
//                                     )
//                                   : null)),
//                     ),
//                     child: _thumbnailFile == null
//                         ? const Center(
//                             child: Text(
//                               "Tap to upload thumbnail",
//                               style: TextStyle(color: Colors.grey),
//                             ),
//                           )
//                         : null,
//                   ),
//                 ),
//                 if (_uploadingImage)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         LinearProgressIndicator(value: _uploadProgress),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
//                           style: const TextStyle(fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Active",
//                       style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500),
//                     ),
//                     Switch(
//                       value: _active,
//                       activeColor: Colors.green,
//                       onChanged: (v) => setState(() => _active = v),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.black,
//                       foregroundColor: Colors.white,
//                     ),
//                     onPressed: (_loading || _uploadingImage) ? null : _submit,
//                     child: _loading
//                         ? const CircularProgressIndicator(color: Colors.white)
//                         : const Text("OK"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<String?> _uploadThumbnail() async {
//     try {
//       setState(() {
//         _uploadingImage = true;
//         _uploadProgress = 0;
//       });

//       final fileName = 'movie_${DateTime.now().millisecondsSinceEpoch}.jpg';

//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('movies_thumbnail')
//           .child(fileName);

//       UploadTask uploadTask;

//       if (kIsWeb) {
//         uploadTask = ref.putData(_thumbnailBytes!);
//       } else {
//         uploadTask = ref.putFile(_thumbnailFile!);
//       }

//       uploadTask.snapshotEvents.listen((event) {
//         setState(() {
//           _uploadProgress = event.bytesTransferred / event.totalBytes;
//         });
//       });

//       final snapshot = await uploadTask;
//       final downloadUrl = await snapshot.ref.getDownloadURL();

//       thumbnailUrl.text = downloadUrl;
//       return downloadUrl;
//     } catch (e) {
//       Get.snackbar('Upload Failed', e.toString());
//       return null;
//     } finally {
//       setState(() => _uploadingImage = false);
//     }
//   }

//   // ---------------- WIDGETS ----------------

//   Widget _title(String t) => Text(
//         t,
//         style: const TextStyle(
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//           color: Colors.black, // ✅ BLACK HEADING
//         ),
//       );

//   Widget _field(String label, TextEditingController c,
//       {bool isNumber = false}) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8),
//       child: TextFormField(
//         controller: c,
//         keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//         validator: (value) =>
//             (value == null || value.isEmpty) ? 'Required' : null,
//         style: const TextStyle(color: Colors.black), // ✅ INPUT TEXT BLACK
//         decoration: InputDecoration(
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.black), // ✅ LABEL BLACK
//           hintText: label,
//           hintStyle: const TextStyle(color: Colors.grey),
//           filled: true,
//           fillColor: Colors.grey.shade100,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _dualField(
//       String label, TextEditingController en, TextEditingController hi) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(
//           height: 12,
//         ),
//         Text(
//           label,
//           style: const TextStyle(
//               color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         Row(
//           children: [
//             Expanded(child: _field("EN", en)),
//             const SizedBox(width: 12),
//             Expanded(child: _field("HI", hi)),
//           ],
//         ),
//         const SizedBox(height: 2),
//       ],
//     );
//   }

// Widget _dualDropdown({
//   required String label,
//   required String? enValue,
//   required String? hiValue,
//   required ValueChanged<String?> onEnChanged,
//   required ValueChanged<String?> onHiChanged,
// }) {
//   final enOptions = ["Movie", "Song"];
//   final hiOptions = ["फ़िल्म", "गाना"];

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const SizedBox(height: 12),
//       Text(
//         label,
//         style: const TextStyle(
//             color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
//       ),
//       const SizedBox(height: 6),
//       Row(
//         children: [
//           // EN Dropdown
//           Expanded(
//             child: FormField<String>(
//               validator: (value) =>
//                   (enValue == null || enValue.isEmpty) ? 'Required' : null,
//               builder: (field) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<String>(
//                           value: enValue,
//                           isExpanded: true,
//                           dropdownColor: Colors.white,
//                           hint: Text("EN",
//                               style: TextStyle(color: Colors.grey.shade600)),
//                           style: TextStyle(
//                               color: enValue != null
//                                   ? Colors.black
//                                   : Colors.grey.shade600),
//                           items: enOptions
//                               .map((e) => DropdownMenuItem(
//                                     value: e,
//                                     child: Text(e,
//                                         style:
//                                             const TextStyle(color: Colors.black)),
//                                   ))
//                               .toList(),
//                           onChanged: (value) {
//                             onEnChanged(value);
//                             field.didChange(value);
//                             setState(() {
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//                     if (field.hasError)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4, left: 4),
//                         child: Text(
//                           field.errorText!,
//                           style:
//                               const TextStyle(color: Colors.red, fontSize: 12),
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             ),
//           ),
//           const SizedBox(width: 12),

//           // HI Dropdown
//           Expanded(
//             child: FormField<String>(
//               validator: (value) =>
//                   (hiValue == null || hiValue.isEmpty) ? 'Required' : null,
//               builder: (field) {
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade100,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<String>(
//                           value: hiValue,
//                           isExpanded: true,
//                           dropdownColor: Colors.white,
//                           hint: Text("HI",
//                               style: TextStyle(color: Colors.grey.shade600)),
//                           style: TextStyle(
//                               color: hiValue != null
//                                   ? Colors.black
//                                   : Colors.grey.shade600),
//                           items: hiOptions
//                               .map((e) => DropdownMenuItem(
//                                     value: e,
//                                     child: Text(e,
//                                         style:
//                                             const TextStyle(color: Colors.black)),
//                                   ))
//                               .toList(),
//                           onChanged: (value) {
//                             onHiChanged(value);
//                             field.didChange(value);
//                             setState(() {
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//                     if (field.hasError)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4, left: 4),
//                         child: Text(
//                           field.errorText!,
//                           style:
//                               const TextStyle(color: Colors.red, fontSize: 12),
//                         ),
//                       ),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       const SizedBox(height: 8),
//     ],
//   );
// }


//   // ---------------- IMAGE PICK ----------------

//   Future<void> _pickThumbnail() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//       allowMultiple: false,
//     );

//     if (result == null || result.files.isEmpty) return;

//     final file = result.files.first;
//     final extension = file.extension?.toLowerCase();

//     if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension)) {
//       Get.snackbar(
//         'Invalid Format',
//         'Please select jpg, jpeg, png, webp, or gif image',
//       );
//       return;
//     }

//     setState(() {
//       if (kIsWeb) {
//         _thumbnailBytes = file.bytes;
//         _thumbnailFile = null;
//       } else {
//         _thumbnailFile = File(file.path!);
//         _thumbnailBytes = null;
//       }
//       thumbnailUrl.clear();
//     });
//   }

//   // ---------------- SUBMIT ----------------

//   Future<void> _submit() async {

import 'dart:io';
import 'dart:typed_data';
import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/controllers/movie_controller.dart';
import 'package:admin/models/Movies.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';

class AddmovieScreen extends StatefulWidget {
  final Movie? movie;

  const AddmovieScreen({Key? key, this.movie}) : super(key: key);

  @override
  State<AddmovieScreen> createState() => _AddmovieScreenState();
}

class _AddmovieScreenState extends State<AddmovieScreen> {
  final _formKey = GlobalKey<FormState>();
  final MovieController _controller = Get.find<MovieController>();
  final CreatorController _creatorController = Get.put(CreatorController());

  // EN / HI controllers
  final titleEn = TextEditingController();
  final titleHi = TextEditingController();
  final descEn = TextEditingController();
  final descHi = TextEditingController();
  final durationEn = TextEditingController();
  final durationHi = TextEditingController();
  final releaseYearEn = TextEditingController();
  final releaseYearHi = TextEditingController();
  String? categoryEn;
  String? categoryHi;
  String? cbfcEn;
  String? cbfcHi;
  final directorEn = TextEditingController();
  final directorHi = TextEditingController();
  final starcastEn = TextEditingController();
  final starcastHi = TextEditingController();

  // Single fields
  Timestamp? releaseDate;
  final releaseDateController = TextEditingController();

  final videoUrl2 = TextEditingController();
  final thumbnailUrl = TextEditingController();
  String _selectedCreatorId = 'admin';

  bool _active = false;
  bool _loading = false;
  File? _thumbnailFile;
  Uint8List? _thumbnailBytes;
  double _uploadProgress = 0.0;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.movie != null) {
      final m = widget.movie!;
      titleEn.text = m.title?['en'] ?? '';
      titleHi.text = m.title?['hi'] ?? '';
      descEn.text = m.description?['en'] ?? '';
      descHi.text = m.description?['hi'] ?? '';
      durationEn.text = m.duration?['en'] ?? '';
      durationHi.text = m.duration?['hi'] ?? '';
      releaseYearEn.text = m.releaseYear?['en'] ?? '';
      releaseYearHi.text = m.releaseYear?['hi'] ?? '';
      categoryEn = m.category?['en'] ?? '';
      categoryHi = m.category?['hi'] ?? '';
      cbfcEn = m.cbfc?['en'] ?? '';
      cbfcHi = m.cbfc?['hi'] ?? '';
      directorEn.text = m.director?['en'] ?? '';
      directorHi.text = m.director?['hi'] ?? '';
      starcastEn.text = m.starcast?['en'] ?? '';
      starcastHi.text = m.starcast?['hi'] ?? '';
      releaseDate = m.releaseDate;
      if (releaseDate != null) {
        releaseDateController.text =
            DateFormat('yyyy-MM-dd HH:mm').format(releaseDate!.toDate());
      }
      videoUrl2.text = m.videoUrl2 ?? '';
      thumbnailUrl.text = m.thumbnailUrl ?? '';
      _selectedCreatorId = m.creatorId ?? 'admin';
      _active = m.active;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),

                // Movie Details Card
                _buildCard(
                  title: "Movie Details",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dualField("Title", titleEn, titleHi),
                      _dualField("Description", descEn, descHi),
                      _dualField("Duration", durationEn, durationHi),
                      Text(
                        'Ex: 1h 42m, 1 घंटे 42 मिनट',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      _dualField("Release Year", releaseYearEn, releaseYearHi),
                    ],
                  ),
                ),

                // Category & CBFC Card
                _buildCard(
                  title: "Category & CBFC",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dualDropdown(
                        label: "Category",
                        enValue: categoryEn,
                        hiValue: categoryHi,
                        enOptions: ["Movie", "Song"],
                        hiOptions: ["फ़िल्म", "गाना"],
                        onEnChanged: (val) => categoryEn = val,
                        onHiChanged: (val) => categoryHi = val,
                      ),
                      _dualDropdown(
                        label: "CBFC",
                        enValue: cbfcEn,
                        hiValue: cbfcHi,
                         enOptions: ['U', 'U/A 13+', 'U/A 16+', 'A'],
                        hiOptions: ['यू','यू/ए 13+','यू/ए 16+','ए'],
                        onEnChanged: (val) => cbfcEn = val,
                        onHiChanged: (val) => cbfcHi = val,
                      ),
                      Text(
                        'Ex: U/A 13+, यू/ए 13+',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

                // Crew Card
                _buildCard(
                  title: "Crew",
                  child: Column(
                    children: [
                      _dualField("Director", directorEn, directorHi),
                      _dualField("Starcast", starcastEn, starcastHi),
                    ],
                  ),
                ),

                // Media Card
                _buildCard(
                  title: "Media",
                  child: Column(
                    children: [
                      _field("Video URL", videoUrl2),
                      const SizedBox(height: 12),
                      _buildReleaseDatePicker(),
                      const SizedBox(height: 12),
                      _buildCreatorDropdown(),
                      const SizedBox(height: 12),
                      _buildThumbnailPicker(),
                    ],
                  ),
                ),

                // Settings Card
                _buildCard(
                  title: "Settings",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Active",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black)),
                      Switch(
                          value: _active,
                          activeColor: Colors.green,
                          onChanged: (v) => setState(() => _active = v)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------- WIDGETS ----------------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.movie != null ? "Edit Movie" : "Add Movie",
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.cancel_presentation, size: 32, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
          const SizedBox(height: 12),
          child
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hint: Text(label,
                      style: TextStyle(color: Colors.grey.shade600)),
          labelStyle: const TextStyle(color: Colors.black),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dualField(String label, TextEditingController en, TextEditingController hi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _field("EN", en)),
            const SizedBox(width: 12),
            Expanded(child: _field("HI", hi)),
          ],
        ),
      ],
    );
  }

  Widget _dualDropdown({
    required String label,
    required String? enValue,
    required String? hiValue,
    required List<String> enOptions,
    required List<String> hiOptions,
    required ValueChanged<String?> onEnChanged,
    required ValueChanged<String?> onHiChanged,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: enValue,
                items: enOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                onChanged: onEnChanged,
                dropdownColor: Colors.white,
                hint: Text("EN",
                        style: TextStyle(color: Colors.grey.shade600)),
                style: const TextStyle(
                color: Colors.black, 
                fontSize: 16,
              ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: hiValue,
                items: hiOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                onChanged: onHiChanged,
                dropdownColor: Colors.white,
                hint: Text("HI",
                      style: TextStyle(color: Colors.grey.shade600)),
                style: const TextStyle(
                color: Colors.black, 
                fontSize: 16,
              ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReleaseDatePicker() {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final currentVal = releaseDate?.toDate() ?? now;
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: currentVal,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(currentVal),
          );
          if (pickedTime != null) {
            final newDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            setState(() {
              releaseDate = Timestamp.fromDate(newDateTime);
              releaseDateController.text =
                  DateFormat('yyyy-MM-dd HH:mm').format(newDateTime);
            });
          }
        }
      },
      child: AbsorbPointer(
        child: _field("Release Date", releaseDateController),
      ),
    );
  }

  Widget _buildCreatorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Creator",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,color: Colors.black)),
        const SizedBox(height: 8),
        Obx(() {
          if (_creatorController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          List<DropdownMenuItem<String>> items = [
            const DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ..._creatorController.creators
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name ?? 'Unknown')))
          ];
          if (!items.any((i) => i.value == _selectedCreatorId)) _selectedCreatorId = 'admin';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCreatorId,
                isExpanded: true,
                dropdownColor: Colors.white,
                items: items,
                onChanged: (val) => setState(() => _selectedCreatorId = val ?? 'admin'),
                style: const TextStyle(
                color: Colors.black, 
                fontSize: 16,
              ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildThumbnailPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Thumbnail", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickThumbnail,
          child: DottedBorder(
            color: Colors.grey,
            borderType: BorderType.RRect,
            radius: const Radius.circular(8),
            dashPattern: [6, 4],
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: kIsWeb
                    ? (_thumbnailBytes != null
                        ? DecorationImage(image: MemoryImage(_thumbnailBytes!), fit: BoxFit.cover)
                        : (thumbnailUrl.text.isNotEmpty
                            ? DecorationImage(image: NetworkImage(thumbnailUrl.text), fit: BoxFit.cover)
                            : null))
                    : (_thumbnailFile != null
                        ? DecorationImage(image: FileImage(_thumbnailFile!), fit: BoxFit.cover)
                        : (thumbnailUrl.text.isNotEmpty
                            ? DecorationImage(image: NetworkImage(thumbnailUrl.text), fit: BoxFit.cover)
                            : null)),
              ),
              child: (_thumbnailFile == null && _thumbnailBytes == null && thumbnailUrl.text.isEmpty)
                  ? const Center(child: Text("Tap to upload thumbnail", style: TextStyle(color: Colors.grey)))
                  : null,
            ),
          ),
        ),
        if (_uploadingImage)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text('Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_loading || _uploadingImage) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.lightBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Save Movie", style: TextStyle(fontSize: 16,color: Colors.white)),
      ),
    );
  }

  // ---------------- IMAGE PICK & UPLOAD ----------------

  Future<void> _pickThumbnail() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final ext = file.extension?.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      Get.snackbar('Invalid Format', 'Please select jpg, jpeg, png, webp, or gif');
      return;
    }
    setState(() {
      if (kIsWeb) {
        _thumbnailBytes = file.bytes;
        _thumbnailFile = null;
      } else {
        _thumbnailFile = File(file.path!);
        _thumbnailBytes = null;
      }
      thumbnailUrl.clear();
    });
  }

  Future<String?> _uploadThumbnail() async {
    try {
      setState(() {
        _uploadingImage = true;
        _uploadProgress = 0;
      });
      final fileName = 'movie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('movies_thumbnail').child(fileName);
      UploadTask task = kIsWeb ? ref.putData(_thumbnailBytes!) : ref.putFile(_thumbnailFile!);

      task.snapshotEvents.listen((e) => setState(() => _uploadProgress = e.bytesTransferred / e.totalBytes));

      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      thumbnailUrl.text = url;
      return url;
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString());
      return null;
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  // ---------------- SUBMIT ----------------

  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    String? uploadedThumbnailUrl = thumbnailUrl.text;

    if (_thumbnailFile != null || _thumbnailBytes != null) {
      final url = await _uploadThumbnail();
      if (url == null) {
        setState(() => _loading = false);
        return;
      }
      uploadedThumbnailUrl = url;
    }

    // Save movie with uploaded URL
    final payload = {
      'title': {'en': titleEn.text, 'hi': titleHi.text},
      'description': {'en': descEn.text, 'hi': descHi.text},
      'duration': {'en': durationEn.text, 'hi': durationHi.text},
      'releaseYear': {'en': releaseYearEn.text, 'hi': releaseYearHi.text},
      'category': {'en': categoryEn, 'hi': categoryHi},
      'cbfc': {'en': cbfcEn, 'hi': cbfcHi},
      'director': {'en': directorEn.text, 'hi': directorHi.text},
      'starcast': {'en': starcastEn.text, 'hi': starcastHi.text},
      'createdAt': FieldValue.serverTimestamp(),
      'releaseDate': releaseDate ?? FieldValue.serverTimestamp(),
      'views': 0,
      'videoUrl': "",
      'videoUrl2': videoUrl2.text,
      'creatorId': _selectedCreatorId,
      'thumbnailUrl': uploadedThumbnailUrl,
      'active': _active,
    };

    try {
      if (widget.movie != null) {
        await _controller.updateMovie(movieId: widget.movie!.id, data: payload);
      } else {
        await _controller.createMovie(payload);
      }

      Get.snackbar('Success', 'Movie saved successfully');
      Navigator.pop(context);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }
}
