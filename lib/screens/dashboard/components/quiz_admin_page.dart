import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_pkg;
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:translator/translator.dart';
import 'package:intl/intl.dart';

class QuizAdminPage extends StatefulWidget {
  const QuizAdminPage({Key? key}) : super(key: key);

  @override
  State<QuizAdminPage> createState() => _QuizAdminPageState();
}

class _QuizAdminPageState extends State<QuizAdminPage> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final _coinsRewardController = TextEditingController();
  int _correctAnswerIndex = 0;
  String _selectedLanguage = 'en';
  bool _isActive = true;
  String? _editingQuestionId;
  String? _editingLanguageDoc; // 'hindi' or 'english'
  DateTime _scheduledAt = DateTime.now();

  String _langDocId(String langCode) => langCode == 'hi' ? 'hindi' : 'english';

  void _submitQuestion() async {
    if (_questionController.text.isEmpty || _optionControllers.any((c) => c.text.isEmpty)) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    try {
      final data = {
        'question': _questionController.text,
        'options': _optionControllers.map((c) => c.text).toList(),
        'correctAnswerIndex': _correctAnswerIndex,
        'language': _selectedLanguage,
        'isActive': _isActive,
        'scheduledAt': Timestamp.fromDate(_scheduledAt),
        'coinsReward': int.tryParse(_coinsRewardController.text.trim()) ?? 0,
      };

      debugPrint('Attempting to save quiz data: $data');

      if (_editingQuestionId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _saveQuizInBothLanguages(data);
        Get.snackbar('Success', 'Question added in both languages successfully');
      } else {
        final langDoc = _editingLanguageDoc ?? _langDocId(_selectedLanguage);
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(langDoc)
            .collection('questions')
            .doc(_editingQuestionId)
            .update(data);
        Get.snackbar('Success', 'Question updated successfully');
      }

      _resetForm();
    } catch (e) {
      debugPrint('Error saving question: $e');
      Get.snackbar('Error', 'Failed to save question: $e', 
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveQuizInBothLanguages(Map<String, dynamic> quizData) async {
    final translator = GoogleTranslator();

    String originalLang = quizData['language'] ?? 'en';
    String targetLang = originalLang == 'en' ? 'hi' : 'en';

    // Mark original so admin panel can filter to show only uploaded language
    quizData['isOriginal'] = true;

    // Save original to its language sub-collection (quizzes/hindi/questions or quizzes/english/questions)
    await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(_langDocId(originalLang))
        .collection('questions')
        .add(quizData);

    // Build translated copy
    Map<String, dynamic> copy = Map.from(quizData);
    copy['language'] = targetLang;
    copy['isOriginal'] = false; // auto-translated, not shown in admin list

    var translatedQuestion = await translator.translate(
      quizData['question'],
      from: originalLang,
      to: targetLang,
    );
    copy['question'] = translatedQuestion.text;

    List<String> originalOptions = List<String>.from(quizData['options']);
    List<String> translatedOptions = [];
    for (var opt in originalOptions) {
      var transOpt = await translator.translate(
        opt,
        from: originalLang,
        to: targetLang,
      );
      translatedOptions.add(transOpt.text);
    }
    copy['options'] = translatedOptions;

    // Save translated copy to the other language sub-collection
    await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(_langDocId(targetLang))
        .collection('questions')
        .add(copy);
  }

  void _resetForm() {
    setState(() {
      _questionController.clear();
      for (var c in _optionControllers) {
        c.clear();
      }
      _coinsRewardController.clear();
      _correctAnswerIndex = 0;
      _selectedLanguage = 'en';
      _isActive = true;
      _editingQuestionId = null;
      _editingLanguageDoc = null;
      _scheduledAt = DateTime.now();
    });
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      );
      if (pickedTime != null) {
        setState(() {
          _scheduledAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final dateStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    final timeStr = TimeOfDay.fromDateTime(dt).format(context);
    return "$dateStr $timeStr";
  }

  Future<void> _pickAndImportFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'pdf'],
        withData: true,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        List<Map<String, dynamic>> extractedQuizzes = [];

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File picked: ${file.name}'), duration: const Duration(seconds: 2)),
        );

        String ext = file.extension?.toLowerCase() ?? '';
        
        if (ext == 'csv') {
          String content = utf8.decode(file.bytes!);
          extractedQuizzes = _parseCsv(content);
        } else if (ext == 'xlsx' || ext == 'xls') {
          extractedQuizzes = _parseExcel(file.bytes!);
        } else if (ext == 'pdf') {
          extractedQuizzes = await _parsePdf(file.bytes!, context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unsupported file extension: $ext')),
          );
          return;
        }

        if (extractedQuizzes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No valid quizzes found in file')),
          );
          return;
        }

        // Show confirmation dialog
        _showImportConfirmation(extractedQuizzes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import file: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _parseCsv(String content) {
    List<List<dynamic>> rows = const CsvToListConverter().convert(content);
    List<Map<String, dynamic>> quizzes = [];

    for (var row in rows) {
      if (row.length >= 6) {
        quizzes.add({
          'question': row[0].toString(),
          'options': [row[1].toString(), row[2].toString(), row[3].toString(), row[4].toString()],
          'correctAnswerIndex': int.tryParse(row[5].toString()) ?? 0,
          'language': row.length > 6 ? row[6].toString() : 'en',
          'isActive': true,
        });
      }
    }
    return quizzes;
  }

  List<Map<String, dynamic>> _parseExcel(Uint8List bytes) {
    var excel = excel_pkg.Excel.decodeBytes(bytes);
    List<Map<String, dynamic>> quizzes = [];

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        if (row.length >= 6) {
          quizzes.add({
            'question': row[0]?.value.toString() ?? '',
            'options': [
              row[1]?.value.toString() ?? '',
              row[2]?.value.toString() ?? '',
              row[3]?.value.toString() ?? '',
              row[4]?.value.toString() ?? ''
            ],
            'correctAnswerIndex': int.tryParse(row[5]?.value.toString() ?? '0') ?? 0,
            'language': row.length > 6 ? row[6]?.value.toString() ?? 'en' : 'en',
            'isActive': true,
          });
        }
      }
    }
    return quizzes;
  }

  Future<List<Map<String, dynamic>> > _parsePdf(Uint8List bytes, BuildContext context) async {
    pdf_pkg.PdfDocument document = pdf_pkg.PdfDocument(inputBytes: bytes);
    String text = pdf_pkg.PdfTextExtractor(document).extractText();
    document.dispose();



    List<Map<String, dynamic>> quizzes = [];
    List<String> lines = text.split('\n').map((e) => e.trim()).toList();
    
    String currentQuestion = '';
    List<String> currentOptions = [];
    int currentCorrectIndex = 0;
    String currentLanguage = 'en';
    
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.isEmpty) continue;

      if (line == 'Question (Text)') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentQuestion = lines[j];
      } else if (line == 'Option 1 (Text)') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentOptions.add(lines[j]);
      } else if (line == 'Option 2 (Text)') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentOptions.add(lines[j]);
      } else if (line == 'Option 3 (Text)') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentOptions.add(lines[j]);
      } else if (line == 'Option 4 (Text)') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentOptions.add(lines[j]);
      } else if (line == 'Correct Answer Index') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentCorrectIndex = int.tryParse(lines[j]) ?? 0;
      } else if (line == 'Language') {
        int j = i + 1;
        while (j < lines.length && lines[j].isEmpty) j++;
        if (j < lines.length) currentLanguage = lines[j];
        
        // Save the quiz
        if (currentQuestion.isNotEmpty && currentOptions.length >= 4) {
          quizzes.add({
            'question': currentQuestion,
            'options': currentOptions.sublist(0, 4),
            'correctAnswerIndex': currentCorrectIndex,
            'language': currentLanguage.isNotEmpty ? currentLanguage : 'en',
            'isActive': true,
          });
          // Reset for next question
          currentQuestion = '';
          currentOptions = [];
          currentCorrectIndex = 0;
          currentLanguage = 'en';
        }
      }
    }
    
    if (quizzes.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Parsing Result'),
          content: const Text('Failed to parse any quizzes from the PDF. Please check the format.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    }
    
    return quizzes;
  }

  void _publishActiveQuiz() async {
    // This function is now deprecated in favor of individual 'isActive' toggles
    Get.snackbar('Notice', 'Publish button is no longer needed. Use the "Active" toggle on each question instead.');
  }

  void _showImportConfirmation(List<Map<String, dynamic>> quizzes) {
    for (var quiz in quizzes) {
      quiz['scheduledAt'] ??= _scheduledAt;
      quiz['coinsReward'] ??= 0;
    }

    // One TextEditingController per quiz for the coins field
    final coinsControllers = List.generate(
      quizzes.length,
      (i) => TextEditingController(text: (quizzes[i]['coinsReward'] ?? 0).toString()),
    );

    // Global apply-to-all controller
    final globalCoinsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Global apply-to-all state
          DateTime globalTime = _scheduledAt;

          void applyGlobalTime(DateTime t) {
            setDialogState(() {
              for (int i = 0; i < quizzes.length; i++) {
                quizzes[i]['scheduledAt'] = t;
              }
            });
          }

          void applyGlobalActive(bool val) {
            setDialogState(() {
              for (int i = 0; i < quizzes.length; i++) {
                quizzes[i]['isActive'] = val;
              }
            });
          }

          void applyGlobalCoins(String val) {
            final coins = int.tryParse(val) ?? 0;
            setDialogState(() {
              for (int i = 0; i < quizzes.length; i++) {
                quizzes[i]['coinsReward'] = coins;
                coinsControllers[i].text = val;
              }
            });
          }

          return AlertDialog(
            title: Text('Import ${quizzes.length} Quizzes?'),
            content: SizedBox(
              width: 580,
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Global controls banner ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 6),
                        const Text('Apply to All:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(width: 16),
                        // Global Active toggle
                        const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Switch(
                          value: quizzes.every((q) => q['isActive'] == true),
                          onChanged: applyGlobalActive,
                          activeColor: Colors.blueAccent,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Spacer(),
                        // Global time picker
                        const Icon(Icons.access_time, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: globalTime,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(globalTime),
                              );
                              if (pickedTime != null) {
                                final newTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                                globalTime = newTime;
                                applyGlobalTime(newTime);
                              }
                            }
                          },
                          child: Text(
                            quizzes.isNotEmpty && quizzes[0]['scheduledAt'] is DateTime
                                ? TimeOfDay.fromDateTime(quizzes[0]['scheduledAt'] as DateTime).format(context)
                                : TimeOfDay.fromDateTime(_scheduledAt).format(context),
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Global coins input
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 75,
                          height: 32,
                          child: TextField(
                            controller: globalCoinsController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'coins',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber, width: 0.8), borderRadius: BorderRadius.circular(6)),
                              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(6)),
                              filled: true,
                              fillColor: Colors.amber.withOpacity(0.06),
                            ),
                            onChanged: applyGlobalCoins,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Per-quiz list ──
                  Expanded(
                    child: ListView.builder(
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  DateTime scheduledTime = quizzes[index]['scheduledAt'] is DateTime
                      ? quizzes[index]['scheduledAt']
                      : (quizzes[index]['scheduledAt'] as Timestamp).toDate();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    color: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quizzes[index]['question'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Language: ${quizzes[index]['language'] == 'hi' ? 'Hindi' : 'English'}   •   '
                            'Time: ${scheduledTime.toString().substring(0, 16)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Active toggle
                              const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Switch(
                                value: quizzes[index]['isActive'] ?? true,
                                onChanged: (val) => setDialogState(() => quizzes[index]['isActive'] = val),
                                activeColor: Colors.blueAccent,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Spacer(),
                              // Time picker
                              const Icon(Icons.access_time, color: Colors.white54, size: 16),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: scheduledTime,
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (pickedDate != null) {
                                    TimeOfDay? pickedTime = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(scheduledTime),
                                    );
                                    if (pickedTime != null) {
                                      setDialogState(() {
                                        quizzes[index]['scheduledAt'] = DateTime(
                                          pickedDate.year,
                                          pickedDate.month,
                                          pickedDate.day,
                                          pickedTime.hour,
                                          pickedTime.minute,
                                        );
                                      });
                                    }
                                  }
                                },
                                child: Text(
                                  TimeOfDay.fromDateTime(scheduledTime).format(context),
                                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Coins reward input
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 70,
                                height: 32,
                                child: TextField(
                                  controller: coinsControllers[index],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                    suffixText: 'c',
                                    suffixStyle: const TextStyle(color: Colors.amber, fontSize: 11),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.amber, width: 0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Colors.amber),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    filled: true,
                                    fillColor: Colors.amber.withOpacity(0.06),
                                  ),
                                  onChanged: (val) {
                                    quizzes[index]['coinsReward'] = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
                  ],
                ),
              ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Sync coins values from text controllers before saving
                    for (int i = 0; i < quizzes.length; i++) {
                      quizzes[i]['coinsReward'] = int.tryParse(coinsControllers[i].text.trim()) ?? 0;
                    }
                    for (var quiz in quizzes) {
                      quiz['createdAt'] = FieldValue.serverTimestamp();

                      // Ensure scheduledAt is a Timestamp
                      DateTime scheduledDateTime = quiz['scheduledAt'] is DateTime
                          ? quiz['scheduledAt']
                          : (quiz['scheduledAt'] as Timestamp).toDate();
                      quiz['scheduledAt'] = Timestamp.fromDate(scheduledDateTime);

                      await _saveQuizInBothLanguages(quiz);
                    }
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Row(children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Text('Quiz Added Successfully'),
                        ]),
                        content: Text('${quizzes.length} quiz${quizzes.length == 1 ? '' : 'zes'} have been added successfully in both languages.'),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to import quizzes: $e')),
                    );
                  }
                },
                child: const Text('IMPORT & ADD'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _loadQuestionForEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingQuestionId = doc.id;
      // Derive which language document this quiz lives under
      _editingLanguageDoc = doc.reference.parent.parent?.id; // 'hindi' or 'english'
      _questionController.text = data['question'] ?? '';
      List<dynamic> options = data['options'] ?? [];
      for (int i = 0; i < 4; i++) {
        _optionControllers[i].text = i < options.length ? options[i].toString() : '';
      }
      _correctAnswerIndex = data['correctAnswerIndex'] ?? 0;
      _selectedLanguage = data['language'] ?? 'en';
      _isActive = data['isActive'] ?? true;
      _coinsRewardController.text = (data['coinsReward'] ?? 0).toString();
      if (data['scheduledAt'] != null) {
        _scheduledAt = (data['scheduledAt'] as Timestamp).toDate();
      } else {
        _scheduledAt = DateTime.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manage Questions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTextField(_questionController, 'Question', maxLines: 3),
                  const SizedBox(height: 20),
                  const Text('Options', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...List.generate(4, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswerIndex,
                          onChanged: (val) => setState(() => _correctAnswerIndex = val!),
                          activeColor: Colors.blueAccent,
                        ),
                        Expanded(child: _buildTextField(_optionControllers[index], 'Option ${index + 1}')),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Language: ', style: TextStyle(color: Colors.white70)),
                      DropdownButton<String>(
                        value: _selectedLanguage,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('Hindi')),
                        ],
                        onChanged: (val) => setState(() => _selectedLanguage = val!),
                      ),
                      const Spacer(),
                      const Text('Active: ', style: TextStyle(color: Colors.white70)),
                      Switch(
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        activeColor: Colors.blueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Scheduled At: ', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: _selectDateTime,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _formatDateTime(_scheduledAt),
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      const Text('Coins Reward: ', style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _coinsRewardController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: const TextStyle(color: Colors.white38),
                            suffixText: 'coins',
                            suffixStyle: const TextStyle(color: Colors.amber, fontSize: 12),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(8)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitQuestion,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                            child: Text(_editingQuestionId == null ? 'ADD QUESTION' : 'UPDATE QUESTION', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _pickAndImportFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('BULK IMPORT'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.blueAccent),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_editingQuestionId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                          ),
                          child: const Text('CANCEL EDIT', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Questions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          Get.defaultDialog(
                            title: 'Delete All?',
                            middleText: 'Are you sure you want to delete all existing quizzes?',
                            textConfirm: 'YES, DELETE ALL',
                            textCancel: 'CANCEL',
                            confirmTextColor: Colors.white,
                            onConfirm: () async {
                              try {
                                final hindiDocs = await FirebaseFirestore.instance
                                    .collection('quizzes').doc('hindi').collection('questions').get();
                                final englishDocs = await FirebaseFirestore.instance
                                    .collection('quizzes').doc('english').collection('questions').get();
                                final batch = FirebaseFirestore.instance.batch();
                                for (var doc in hindiDocs.docs) {
                                  batch.delete(doc.reference);
                                }
                                for (var doc in englishDocs.docs) {
                                  batch.delete(doc.reference);
                                }
                                await batch.commit();
                                Get.back();
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Row(children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      SizedBox(width: 10),
                                      Text('Deleted Successfully'),
                                    ]),
                                    content: const Text('All quizzes have been deleted successfully.'),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                Get.back();
                                Get.snackbar('Error', 'Failed to delete quizzes: $e');
                              }
                            },
                          );
                        },
                        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                        label: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildQuestionsList(),
                ],
              ),
            ),
          ),
          Container(width: 1, color: Colors.white24),
          Expanded(
            flex: 1,
            child: const QuizReportsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildQuestionsList() {
    // Listen to both language sub-collections simultaneously — no Firebase index needed
    final hindiStream = FirebaseFirestore.instance
        .collection('quizzes').doc('hindi').collection('questions').snapshots();
    final englishStream = FirebaseFirestore.instance
        .collection('quizzes').doc('english').collection('questions').snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: hindiStream,
      builder: (context, hindiSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: englishStream,
          builder: (context, englishSnap) {
            final isLoading = hindiSnap.connectionState == ConnectionState.waiting ||
                englishSnap.connectionState == ConnectionState.waiting;
            if (isLoading) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ));
            }

            if (hindiSnap.hasError || englishSnap.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Error: ${hindiSnap.error ?? englishSnap.error}',
                    style: const TextStyle(color: Colors.redAccent)),
              );
            }

            // Only show the originally uploaded quiz, not the auto-translated copy
            final docs = [
              ...(hindiSnap.data?.docs ?? []),
              ...(englishSnap.data?.docs ?? []),
            ].where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return d['isOriginal'] != false;
            }).toList();

            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No questions added yet.', style: TextStyle(color: Colors.white38)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final scheduledTs = data['scheduledAt'] as Timestamp?;
                final isScheduled = scheduledTs != null && scheduledTs.toDate().isAfter(DateTime.now());

                return ListTile(
                  title: Text(data['question'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Row(
                    children: [
                      Text(data['language'] == 'en' ? 'English' : 'Hindi', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(width: 10),
                      if (data['isActive'] == true) ...[
                        const Icon(Icons.check_circle, color: Colors.green, size: 12),
                        const SizedBox(width: 4),
                        const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ] else ...[
                        const Icon(Icons.cancel, color: Colors.redAccent, size: 12),
                        const SizedBox(width: 4),
                        const Text('Disabled', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ],
                      const SizedBox(width: 10),
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                      const SizedBox(width: 2),
                      Text('${data['coinsReward'] ?? 0} coins', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                      if (isScheduled) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            'Scheduled: ${_formatDateTime(scheduledTs.toDate())}',
                            style: const TextStyle(color: Colors.amber, fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                        onPressed: () => _loadQuestionForEdit(docs[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          try {
                            await docs[index].reference.delete();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quiz deleted successfully')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete quiz: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Prize Tier Model ────────────────────────────────────────────────────────

class _PrizeTier {
  final int id;
  final String label;
  final int rankFrom;
  final int rankTo;
  final Color color;
  final IconData icon;
  // 'coins' or 'voucher'
  String rewardType;
  int coinsAmount;
  String voucherDescription;

  _PrizeTier({
    required this.id,
    required this.label,
    required this.rankFrom,
    required this.rankTo,
    required this.color,
    required this.icon,
    required this.rewardType,
    required this.coinsAmount,
    required this.voucherDescription,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'rewardType': rewardType,
        'coinsAmount': coinsAmount,
        'voucherDescription': voucherDescription,
      };

  factory _PrizeTier.fromMap(Map<String, dynamic> m, _PrizeTier defaults) =>
      _PrizeTier(
        id: defaults.id,
        label: defaults.label,
        rankFrom: defaults.rankFrom,
        rankTo: defaults.rankTo,
        color: defaults.color,
        icon: defaults.icon,
        rewardType: m['rewardType'] ?? defaults.rewardType,
        coinsAmount: (m['coinsAmount'] as int?) ?? defaults.coinsAmount,
        voucherDescription:
            m['voucherDescription'] ?? defaults.voucherDescription,
      );
}

List<_PrizeTier> _defaultTiers() => [
      _PrizeTier(
        id: 1,
        label: 'Gold',
        rankFrom: 1,
        rankTo: 1,
        color: const Color(0xFFFFD700),
        icon: Icons.emoji_events_rounded,
        rewardType: 'coins',
        coinsAmount: 500,
        voucherDescription: 'Gold Winner Voucher',
      ),
      _PrizeTier(
        id: 2,
        label: 'Silver',
        rankFrom: 2,
        rankTo: 10,
        color: const Color(0xFFB0BEC5),
        icon: Icons.workspace_premium_rounded,
        rewardType: 'coins',
        coinsAmount: 200,
        voucherDescription: 'Silver Winner Voucher',
      ),
      _PrizeTier(
        id: 3,
        label: 'Bronze',
        rankFrom: 11,
        rankTo: 50,
        color: const Color(0xFFCD7F32),
        icon: Icons.military_tech_rounded,
        rewardType: 'coins',
        coinsAmount: 100,
        voucherDescription: 'Bronze Winner Voucher',
      ),
      _PrizeTier(
        id: 4,
        label: 'Finisher',
        rankFrom: 51,
        rankTo: 100,
        color: const Color(0xFF4DB6AC),
        icon: Icons.star_rounded,
        rewardType: 'coins',
        coinsAmount: 50,
        voucherDescription: 'Finisher Reward Voucher',
      ),
    ];

// ─── QuizReportsPanel ────────────────────────────────────────────────────────

class QuizReportsPanel extends StatefulWidget {
  const QuizReportsPanel({Key? key}) : super(key: key);

  @override
  State<QuizReportsPanel> createState() => _QuizReportsPanelState();
}

class _QuizReportsPanelState extends State<QuizReportsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_PrizeTier> _tiers = _defaultTiers();
  bool _selectingWinners = false;
  bool _generatingCertificates = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrizeTiers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Firestore helpers ──────────────────────────────────────────────────────

  Future<void> _loadPrizeTiers() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('quiz_prize_config')
          .doc('tiers')
          .get();
      if (!doc.exists) return;
      final list = doc.data()?['tiers'] as List<dynamic>?;
      if (list == null || list.length < 4) return;
      final defaults = _defaultTiers();
      setState(() {
        _tiers = List.generate(
            4,
            (i) => _PrizeTier.fromMap(
                Map<String, dynamic>.from(list[i] as Map), defaults[i]));
      });
    } catch (_) {}
  }

  Future<void> _savePrizeTiers() async {
    await FirebaseFirestore.instance
        .collection('quiz_prize_config')
        .doc('tiers')
        .set({'tiers': _tiers.map((t) => t.toMap()).toList()});
  }

  String _generateVoucherCode(String tierLabel) {
    const tierCodes = {
      'Gold': 'GLD',
      'Silver': 'SLV',
      'Bronze': 'BRZ',
      'Finisher': 'FIN',
    };
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    final suffix =
        List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
    return 'VA-${tierCodes[tierLabel] ?? 'QZ'}-$suffix';
  }

  _PrizeTier _tierForRank(int rank) {
    for (final t in _tiers) {
      if (rank >= t.rankFrom && rank <= t.rankTo) return t;
    }
    return _tiers.last;
  }

  Future<void> _selectWinners(BuildContext context) async {
    // Confirm before overwriting existing winners
    final existing = await FirebaseFirestore.instance
        .collection('quiz_winners')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Expanded(
                child: Text('Replace Existing Winners?',
                    style: TextStyle(color: Colors.white, fontSize: 16))),
          ]),
          content: const Text(
            'A winner list already exists. Selecting new winners will clear the old list and replace it.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Replace')),
          ],
        ),
      );
      if (overwrite != true) return;
    }

    setState(() => _selectingWinners = true);
    try {
      // 1. Fetch all leaderboard entries
      final snap = await FirebaseFirestore.instance
          .collection('quiz_leaderboard')
          .get();

      // 2. Deduplicate by phoneNumber — keep best score, then fastest time
      final Map<String, Map<String, dynamic>> best = {};
      for (final doc in snap.docs) {
        final d = Map<String, dynamic>.from(doc.data());
        d['_docId'] = doc.id;
        final key = (d['phoneNumber'] as String?)?.trim().isNotEmpty == true
            ? d['phoneNumber'] as String
            : (d['userName'] ?? doc.id) as String;
        if (!best.containsKey(key)) {
          best[key] = d;
        } else {
          final existingScore = best[key]!['score'] as int? ?? 0;
          final newScore = d['score'] as int? ?? 0;
          final existingTime = best[key]!['timeTakenSeconds'] as int? ?? 9999;
          final newTime = d['timeTakenSeconds'] as int? ?? 9999;
          if (newScore > existingScore ||
              (newScore == existingScore && newTime < existingTime)) {
            best[key] = d;
          }
        }
      }

      // 3. Sort: score desc, time asc
      final sorted = best.values.toList()
        ..sort((a, b) {
          final sa = a['score'] as int? ?? 0;
          final sb = b['score'] as int? ?? 0;
          if (sb != sa) return sb.compareTo(sa);
          final ta = a['timeTakenSeconds'] as int? ?? 9999;
          final tb = b['timeTakenSeconds'] as int? ?? 9999;
          return ta.compareTo(tb);
        });

      final top100 = sorted.take(100).toList();

      // 4. Build winner list — reward type decided by tier config
      final List<Map<String, dynamic>> winners = [];
      for (int i = 0; i < top100.length; i++) {
        final entry = top100[i];
        final phone = entry['phoneNumber'] as String? ?? '';
        final rank = i + 1;
        final tier = _tierForRank(rank);
        final isVoucher = tier.rewardType == 'voucher';
        winners.add({
          'rank': rank,
          'userName': entry['userName'] ?? 'Anonymous',
          'phoneNumber': phone,
          'score': entry['score'] ?? 0,
          'correctAnswers': entry['correctAnswers'] ?? 0,
          'timeTakenSeconds': entry['timeTakenSeconds'] ?? 0,
          'tierLabel': tier.label,
          'tierId': tier.id,
          'rewardType': tier.rewardType,
          'coinsAmount': tier.coinsAmount,
          'voucherDescription': tier.voucherDescription,
          'voucherCode': isVoucher ? _generateVoucherCode(tier.label) : '',
          'status': 'pending',
          'certificateEnabled': false,
          'certificateUrl': '',
          'selectedAt': Timestamp.now(),
        });
      }

      // 5. Delete old winners and batch write new ones
      final oldWinners =
          await FirebaseFirestore.instance.collection('quiz_winners').get();
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int opCount = 0;
      for (final doc in oldWinners.docs) {
        batch.delete(doc.reference);
        opCount++;
        if (opCount >= 499) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          opCount = 0;
        }
      }
      for (final w in winners) {
        batch.set(
            FirebaseFirestore.instance.collection('quiz_winners').doc(), w);
        opCount++;
        if (opCount >= 499) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          opCount = 0;
        }
      }
      if (opCount > 0) await batch.commit();

      setState(() => _selectingWinners = false);
      _tabController.animateTo(1);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${winners.length} winners selected and rewards assigned!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      setState(() => _selectingWinners = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to select winners: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  Future<void> _markAllSent(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark All as Sent?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This marks all pending vouchers as sent. Use this after distributing rewards.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Mark Sent')),
        ],
      ),
    );
    if (confirm != true) return;
    final docs = await FirebaseFirestore.instance
        .collection('quiz_winners')
        .where('status', isEqualTo: 'pending')
        .get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;
    for (final doc in docs.docs) {
      batch.update(doc.reference, {'status': 'sent'});
      count++;
      if (count >= 499) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('All rewards marked as sent'),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Prize config dialog ────────────────────────────────────────────────────

  void _showPrizeConfigDialog(BuildContext context) {
    final workingTiers =
        _tiers.map((t) => _PrizeTier.fromMap(t.toMap(), t)).toList();
    // One coins-amount controller + one voucher-description controller per tier
    final coinsControllers = workingTiers
        .map((t) => TextEditingController(text: t.coinsAmount.toString()))
        .toList();
    final voucherControllers = workingTiers
        .map((t) => TextEditingController(text: t.voucherDescription))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber),
            SizedBox(width: 10),
            Text('Prize Configuration',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ]),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Coins or Voucher for each tier. Admin decides the reward type.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(4, (i) {
                    final tier = workingTiers[i];
                    final isVoucher = tier.rewardType == 'voucher';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: tier.color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: tier.color.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tier header
                          Row(children: [
                            Icon(tier.icon, color: tier.color, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${tier.label}  •  Rank ${tier.rankFrom == tier.rankTo ? '#${tier.rankFrom}' : '${tier.rankFrom}–${tier.rankTo}'}',
                              style: TextStyle(
                                  color: tier.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          // Reward type toggle
                          Row(children: [
                            const Text('Reward Type:',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            const SizedBox(width: 12),
                            _rewardTypeChip(
                              label: 'Coins',
                              icon: Icons.monetization_on_rounded,
                              selected: !isVoucher,
                              color: Colors.amber,
                              onTap: () => setDialogState(
                                  () => tier.rewardType = 'coins'),
                            ),
                            const SizedBox(width: 8),
                            _rewardTypeChip(
                              label: 'Voucher',
                              icon: Icons.confirmation_number_rounded,
                              selected: isVoucher,
                              color: Colors.purpleAccent,
                              onTap: () => setDialogState(
                                  () => tier.rewardType = 'voucher'),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          // Input field depending on selected type
                          if (!isVoucher)
                            _inputField(
                              controller: coinsControllers[i],
                              label: 'Coins Amount',
                              icon: Icons.monetization_on_rounded,
                              color: Colors.amber,
                              keyboardType: TextInputType.number,
                            )
                          else
                            _inputField(
                              controller: voucherControllers[i],
                              label: 'Voucher Description',
                              icon: Icons.confirmation_number_rounded,
                              color: Colors.purpleAccent,
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white54))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                for (int i = 0; i < 4; i++) {
                  workingTiers[i].coinsAmount =
                      int.tryParse(coinsControllers[i].text.trim()) ??
                          workingTiers[i].coinsAmount;
                  workingTiers[i].voucherDescription =
                      voucherControllers[i].text.trim();
                }
                setState(() => _tiers = workingTiers);
                await _savePrizeTiers();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Prize config saved'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardTypeChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? color : Colors.white24, width: 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 14, color: selected ? color : Colors.white38),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: selected ? color : Colors.white38,
                  fontSize: 12,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ]),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: color.withOpacity(0.7), fontSize: 12),
        prefixIcon:
            Icon(icon, color: color.withOpacity(0.6), size: 18),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: color.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: color)),
      ),
    );
  }

  // ── Certificate generation ────────────────────────────────────────────────

  Future<void> _generateAndEnableCertificates(
      BuildContext context, List<DocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.workspace_premium_rounded,
              color: Colors.amber, size: 24),
          SizedBox(width: 10),
          Text('Generate Certificates?',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        content: Text(
          'This will generate a PDF certificate for each of the ${docs.length} winners, upload to Firebase Storage, and enable download in the user app.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _generatingCertificates = true);
    int done = 0;
    int failed = 0;
    try {
      // Try to load logo bytes (graceful fallback if missing)
      Uint8List? logoBytes;
      try {
        final bd = await rootBundle.load('assets/images/logo.png');
        logoBytes = bd.buffer.asUint8List();
      } catch (_) {}

      final now = DateTime.now();
      final dateStr = DateFormat('d MMMM yyyy').format(now);

      for (final doc in docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['userName'] as String? ?? 'Participant';
          final rank = data['rank'] as int? ?? 0;
          final tierLabel = data['tierLabel'] as String? ?? 'Finisher';
          final total = docs.length;

          // 1. Build PDF
          final pdfBytes = await _buildCertificatePdf(
            userName: name,
            tierLabel: tierLabel,
            rank: rank,
            totalParticipants: total,
            dateStr: dateStr,
            logoBytes: logoBytes,
          );

          // 2. Upload to Firebase Storage
          final ref = FirebaseStorage.instance
              .ref()
              .child('quiz_certificates/${doc.id}.pdf');
          await ref.putData(pdfBytes,
              SettableMetadata(contentType: 'application/pdf'));
          final url = await ref.getDownloadURL();

          // 3. Update Firestore
          await doc.reference.update({
            'certificateUrl': url,
            'certificateEnabled': true,
          });
          done++;
        } catch (_) {
          failed++;
        }
      }
    } finally {
      setState(() => _generatingCertificates = false);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '$done certificate${done == 1 ? '' : 's'} generated & enabled'
          '${failed > 0 ? ' ($failed failed)' : ''}.'),
      backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<Uint8List> _buildCertificatePdf({
    required String userName,
    required String tierLabel,
    required int rank,
    required int totalParticipants,
    required String dateStr,
    Uint8List? logoBytes,
  }) async {
    final doc = pw.Document();

    // Tier colours
    const tierColors = {
      'Gold': pw_pdf.PdfColor.fromInt(0xFFFFD700),
      'Silver': pw_pdf.PdfColor.fromInt(0xFFB0BEC5),
      'Bronze': pw_pdf.PdfColor.fromInt(0xFFCD7F32),
      'Finisher': pw_pdf.PdfColor.fromInt(0xFF4DB6AC),
    };
    final tierColor =
        tierColors[tierLabel] ?? const pw_pdf.PdfColor.fromInt(0xFF4DB6AC);

    // Certificate title by tier
    const titles = {
      'Gold': 'Certificate of Excellence',
      'Silver': 'Certificate of Achievement',
      'Bronze': 'Certificate of Achievement',
      'Finisher': 'Certificate of Participation',
    };
    final certTitle = titles[tierLabel] ?? 'Certificate of Achievement';

    pw.MemoryImage? logo;
    if (logoBytes != null) logo = pw.MemoryImage(logoBytes);

    const bg = pw_pdf.PdfColor.fromInt(0xFF0D0D2B);
    const bgCard = pw_pdf.PdfColor.fromInt(0xFF1A1A3E);
    const white = pw_pdf.PdfColors.white;
    const white70 = pw_pdf.PdfColor.fromInt(0xB3FFFFFF);

    doc.addPage(pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: pw_pdf.PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        buildBackground: (ctx) => pw.Container(color: bg),
      ),
      build: (ctx) => pw.Column(
        children: [
          // ── Header band ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 40, vertical: 20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  const pw_pdf.PdfColor.fromInt(0xFF1A0050),
                  const pw_pdf.PdfColor.fromInt(0xFF0A0A2E),
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(children: [
                  if (logo != null) ...[
                    pw.Container(
                      width: 48,
                      height: 48,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Videos Alarm',
                          style: pw.TextStyle(
                              color: white,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text('Quiz Championship',
                          style: pw.TextStyle(
                              color: white70, fontSize: 11)),
                    ],
                  ),
                ]),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: tierColor,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        tierLabel.toUpperCase(),
                        style: pw.TextStyle(
                            color: white,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Rank #$rank of $totalParticipants',
                        style: pw.TextStyle(
                            color: white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          // ── Main content ──
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 60, vertical: 24),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // Decorative line
                  pw.Row(children: [
                    pw.Expanded(
                        child: pw.Divider(
                            color: tierColor, thickness: 1.5)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16),
                      child: pw.Container(
                        width: 10,
                        height: 10,
                        decoration: pw.BoxDecoration(
                            color: tierColor,
                            shape: pw.BoxShape.circle),
                      ),
                    ),
                    pw.Expanded(
                        child: pw.Divider(
                            color: tierColor, thickness: 1.5)),
                  ]),
                  pw.SizedBox(height: 16),

                  pw.Text(
                    'THIS IS TO CERTIFY THAT',
                    style: pw.TextStyle(
                        color: white70,
                        fontSize: 11,
                        letterSpacing: 3),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    userName,
                    style: pw.TextStyle(
                        color: white,
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    certTitle,
                    style: pw.TextStyle(
                        color: tierColor,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'for outstanding performance in the Videos Alarm Quiz Championship',
                    style: pw.TextStyle(color: white70, fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Achieved Rank #$rank out of $totalParticipants participants',
                    style: pw.TextStyle(
                        color: white70, fontSize: 11),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 16),

                  // Decorative line
                  pw.Row(children: [
                    pw.Expanded(
                        child: pw.Divider(
                            color: tierColor, thickness: 1.5)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 16),
                      child: pw.Container(
                        width: 10,
                        height: 10,
                        decoration: pw.BoxDecoration(
                            color: tierColor,
                            shape: pw.BoxShape.circle),
                      ),
                    ),
                    pw.Expanded(
                        child: pw.Divider(
                            color: tierColor, thickness: 1.5)),
                  ]),
                ],
              ),
            ),
          ),

          // ── Footer ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 40, vertical: 14),
            color: bgCard,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Videos Alarm',
                        style: pw.TextStyle(
                            color: white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11)),
                    pw.Text('Authorized Certificate',
                        style:
                            pw.TextStyle(color: white70, fontSize: 9)),
                  ],
                ),
                pw.Text('Issued: $dateStr',
                    style: pw.TextStyle(
                        color: white70, fontSize: 10)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Quiz Administration',
                        style: pw.TextStyle(
                            color: white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11)),
                    pw.Text('Videos Alarm Platform',
                        style:
                            pw.TextStyle(color: white70, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));

    return doc.save();
  }

  // ── Delete helpers (Reports tab) ──────────────────────────────────────────

  Future<void> _deleteEntry(BuildContext context, DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: Colors.redAccent, size: 24),
          SizedBox(width: 10),
          Text('Delete Entry',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: const Text('Remove this user report from the leaderboard?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await doc.reference.delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report deleted'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  Future<void> _clearAllReports(
      BuildContext context, List<DocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 26),
          SizedBox(width: 10),
          Text('Clear All Reports',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: Text(
            'Permanently delete all ${docs.length} user reports from the leaderboard?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear All')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      const batchLimit = 499;
      int count = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final doc in docs) {
        batch.delete(doc.reference);
        count++;
        if (count >= batchLimit) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cleared ${docs.length} reports'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to clear: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──
        Container(
          color: const Color(0xFF1A1A1A),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Reports'),
              Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: 'Prize Distribution'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReportsTab(),
              _buildWinnersTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Reports tab ────────────────────────────────────────────────────────────

  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_leaderboard')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Recent User Reports',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  if (docs.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _clearAllReports(context, docs),
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.redAccent, size: 16),
                      label: Text('Clear All (${docs.length})',
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            Colors.redAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : docs.isEmpty
                      ? const Center(
                          child: Text('No rankings yet.',
                              style: TextStyle(color: Colors.white38)))
                      : _buildReportsList(docs),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportsList(List<DocumentSnapshot> allDocs) {
    final now = DateTime.now();
    final docs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['timestamp'] == null) return true;
      final ts = (data['timestamp'] as Timestamp).toDate();
      return now.difference(ts).inDays <= 60;
    }).toList();

    if (docs.isEmpty) {
      return const Center(
          child: Text('No rankings in the last 60 days.',
              style: TextStyle(color: Colors.white38)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        final correct = data['correctAnswers'] ??
            (data['score'] != null ? data['score'] ~/ 10 : 0);
        final timeSecs = data['timeTakenSeconds'] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          data['userName'] ?? 'Anonymous',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${data['score']} pts',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ]),
                    if ((data['phoneNumber'] as String?)?.isNotEmpty == true)
                      Text(data['phoneNumber'],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 12),
                      const SizedBox(width: 3),
                      Text('$correct/5',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.timer_outlined,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 3),
                      Text(
                          '${timeSecs ~/ 60}m ${timeSecs % 60}s',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deleteEntry(context, doc),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 18),
                tooltip: 'Delete',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Winners / Prize Distribution tab ─────────────────────────────────────

  Widget _buildWinnersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('quiz_winners')
          .orderBy('rank')
          .snapshots(),
      builder: (context, snapshot) {
        final winners = snapshot.data?.docs ?? [];
        final pending =
            winners.where((d) => (d.data() as Map)['status'] == 'pending').length;
        final sent =
            winners.where((d) => (d.data() as Map)['status'] == 'sent').length;

        return Column(
          children: [
            // ── Winners header ──
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              decoration: const BoxDecoration(
                color: Color(0xFF151515),
                border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1)),
              ),
              child: Column(
                children: [
                  // Tier legend
                  Row(
                    children: _tiers
                        .map((t) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4),
                                decoration: BoxDecoration(
                                  color: t.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: t.color.withOpacity(0.3)),
                                ),
                                child: Column(children: [
                                  Icon(t.icon,
                                      color: t.color, size: 14),
                                  const SizedBox(height: 2),
                                  Text(t.label,
                                      style: TextStyle(
                                          color: t.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    t.rankFrom == t.rankTo
                                        ? '#${t.rankFrom}'
                                        : '${t.rankFrom}-${t.rankTo}',
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 9),
                                  ),
                                ]),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  // Action buttons row
                  Row(
                    children: [
                      // Status summary
                      if (winners.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${winners.length} winners  •  $pending pending  •  $sent sent',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11),
                          ),
                        ),
                        const Spacer(),
                      ] else
                        const Spacer(),
                      // Config button
                      IconButton(
                        onPressed: () =>
                            _showPrizeConfigDialog(context),
                        icon: const Icon(Icons.tune_rounded,
                            color: Colors.white54, size: 18),
                        tooltip: 'Configure prizes',
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                      const SizedBox(width: 6),
                      // Select winners button
                      _selectingWinners
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.amber))
                          : ElevatedButton.icon(
                              onPressed: () =>
                                  _selectWinners(context),
                              icon: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15),
                              label: Text(
                                winners.isEmpty
                                    ? 'Select Top 100'
                                    : 'Re-select',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                            ),
                      if (pending > 0) ...[
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          onPressed: () => _markAllSent(context),
                          icon: const Icon(Icons.send_rounded,
                              size: 14),
                          label: const Text('Mark All Sent',
                              style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                      if (winners.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _generatingCertificates
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.purpleAccent))
                            : ElevatedButton.icon(
                                onPressed: () =>
                                    _generateAndEnableCertificates(
                                        context, winners),
                                icon: const Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 14),
                                label: const Text('Generate Certs',
                                    style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF6C3FC7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                              ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Winners list ──
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : winners.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_outlined,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.1)),
                              const SizedBox(height: 12),
                              const Text('No winners selected yet.',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14)),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap "Select Top 100" to auto-pick winners\nfrom the leaderboard.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white24,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : _buildWinnersList(winners),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWinnersList(List<DocumentSnapshot> docs) {
    final tierMap = {for (final t in _tiers) t.label: t};
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final tierLabel = data['tierLabel'] as String? ?? 'Finisher';
        final tier = tierMap[tierLabel] ?? _tiers.last;
        final rank = data['rank'] as int? ?? (index + 1);
        final isSent = data['status'] == 'sent';
        final certEnabled = data['certificateEnabled'] == true;
        final rewardType = data['rewardType'] as String? ?? 'coins';
        final isVoucher = rewardType == 'voucher';
        final coinsAmount = data['coinsAmount'] as int? ?? 0;
        final voucherCode = data['voucherCode'] as String? ?? '';
        final voucherDescription =
            data['voucherDescription'] as String? ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tier.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tier.color.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank + tier icon
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: tier.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('#$rank',
                          style: TextStyle(
                              color: tier.color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(tier.icon, color: tier.color, size: 14),
                ],
              ),
              const SizedBox(width: 10),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((data['phoneNumber'] as String?)?.isNotEmpty == true)
                      Text(data['phoneNumber'],
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    const SizedBox(height: 6),
                    // Reward — coins or voucher
                    if (!isVoucher)
                      Row(children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: Colors.amber, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '$coinsAmount Coins',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ])
                    else ...[
                      Row(children: [
                        const Icon(Icons.confirmation_number_rounded,
                            color: Colors.purpleAccent, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            voucherDescription,
                            style: const TextStyle(
                                color: Colors.purpleAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      if (voucherCode.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.confirmation_number_outlined,
                              color: Colors.white24, size: 12),
                          const SizedBox(width: 4),
                          SelectableText(
                            voucherCode,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 1.2),
                          ),
                        ]),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Status + score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${data['score']} pts',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSent
                          ? Colors.green.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSent ? '✓ Sent' : '⏳ Pending',
                      style: TextStyle(
                          color:
                              isSent ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Toggle sent status
                  InkWell(
                    onTap: () async {
                      await docs[index].reference.update(
                          {'status': isSent ? 'pending' : 'sent'});
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        isSent ? 'Undo' : 'Mark Sent',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: certEnabled
                          ? Colors.purple.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      certEnabled ? '🎓 Cert On' : 'No Cert',
                      style: TextStyle(
                          color: certEnabled
                              ? Colors.purpleAccent
                              : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
