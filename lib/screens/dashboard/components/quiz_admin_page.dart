import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_pkg;
import 'dart:convert';
import 'dart:typed_data';
import 'package:translator/translator.dart';

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

class QuizReportsPanel extends StatelessWidget {
  const QuizReportsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Recent User Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('quiz_leaderboard')
                .orderBy('timestamp', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No rankings yet.', style: TextStyle(color: Colors.white38)));
              }

              final now = DateTime.now();
              var docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['timestamp'] == null) return true;
                final ts = (data['timestamp'] as Timestamp).toDate();
                return now.difference(ts).inDays <= 60;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text('No rankings in the last 60 days.', style: TextStyle(color: Colors.white38)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final correct = data['correctAnswers'] ?? (data['score'] != null ? data['score'] ~/ 10 : 0);
                  final timeSecs = data['timeTakenSeconds'] ?? 0;
                  final timeStr = '${timeSecs ~/ 60}m ${timeSecs % 60}s';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.white38, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['userName'] ?? 'Anonymous',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  if (data['phoneNumber'] != null)
                                    Text(
                                      data['phoneNumber'],
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '${data['score']} pts',
                              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Correct: $correct/5', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('Time: $timeStr', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
