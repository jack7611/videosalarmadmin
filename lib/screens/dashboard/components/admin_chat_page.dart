import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// --- Dark Theme Color Palette ---
class _DarkThemeColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E); // For cards, dialogs
  static const Color primary = Color(0xFF3B82F6); // A vibrant blue accent
  static const Color adminBubble = primary;
  static const Color userBubble = Color(0xFF374151); // Dark cool gray
  static const Color onPrimary = Colors.white;
  static const Color onSurface = Colors.white;
  static const Color onSurfaceVariant =
      Color(0xFF9E9E9E); // Lighter gray for secondary text
  static const Color error = Color(0xFFEF4444);
}
// --- End Color Palette ---

class AdminChatWindow extends StatefulWidget {
  final String ticketId;
  final String ticketSubject;
  final VoidCallback onClose;

  const AdminChatWindow({
    Key? key,
    required this.ticketId,
    required this.ticketSubject,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AdminChatWindow> createState() => _AdminChatWindowState();
}

class _AdminChatWindowState extends State<AdminChatWindow> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _isUploading = false;
  Map<String, dynamic>? _ticketData;

  @override
  void initState() {
    super.initState();
    _loadTicketData();
  }

  Future<void> _loadTicketData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _ticketData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Error loading ticket data: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) &&
        (imageUrl == null || imageUrl.isEmpty)) {
      return;
    }

    try {
      Map<String, dynamic> messageData = {
        'timestamp': FieldValue.serverTimestamp(),
        'senderRole': 'admin',
        'senderId':
            'admin_user_id', // Replace with actual admin ID if available
      };

      if (text != null && text.isNotEmpty) {
        messageData['type'] = 'text';
        messageData['text'] = text;
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        messageData['type'] = 'image';
        messageData['imageUrl'] = imageUrl;
      }

      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .collection('messages')
          .add(messageData);

      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(widget.ticketId)
          .update({
        'status': 'in-progress',
        'lastReply': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: _DarkThemeColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      setState(() => _isUploading = true);

      final fileName = '${const Uuid().v4()}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.ticketId)
          .child(fileName);

      TaskSnapshot snapshot;
      if (kIsWeb) {
        final fileBytes = await pickedFile.readAsBytes();
        snapshot = await storageRef.putData(
            fileBytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(pickedFile.path);
        snapshot = await storageRef.putFile(file);
      }

      final downloadUrl = await snapshot.ref.getDownloadURL();
      await _sendMessage(imageUrl: downloadUrl);
    } catch (e, stacktrace) {
      debugPrint('Upload error: $e\n$stacktrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: _DarkThemeColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DarkThemeColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildChatHeader(),

          // Ticket Info Bar
          if (_ticketData != null) _buildTicketInfoBar(),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tickets')
                  .doc(widget.ticketId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _DarkThemeColors.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading messages.",
                        style: TextStyle(color: _DarkThemeColors.error)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: _DarkThemeColors.onSurfaceVariant
                                .withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          "No messages yet. Start the conversation!",
                          style: TextStyle(
                              color: _DarkThemeColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final messageDoc = snapshot.data!.docs[index];
                    final data = messageDoc.data() as Map<String, dynamic>;
                    final bool isAdmin = data['senderRole'] == 'admin';

                    return MessageBubble(
                      text: data['text'],
                      imageUrl: data['imageUrl'],
                      timestamp: data['timestamp'] as Timestamp?,
                      isFromAdmin: isAdmin,
                    );
                  },
                );
              },
            ),
          ),

          // Upload Progress
          if (_isUploading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _DarkThemeColors.primary)),
                  const SizedBox(width: 12),
                  Text('Uploading image...',
                      style:
                          TextStyle(color: _DarkThemeColors.onSurfaceVariant)),
                ],
              ),
            ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: _DarkThemeColors.surface, // Header same as body
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          border: Border(
              bottom: BorderSide(color: Color(0xFF374151))) // Subtle separator
          ),
      child: Row(
        children: [
          const Icon(Icons.support_agent,
              color: _DarkThemeColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ticketSubject,
                  style: const TextStyle(
                      color: _DarkThemeColors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_ticketData != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.ticketId.substring(0, 8)}... • ${_ticketData!['name'] ?? 'Unknown User'}',
                    style: TextStyle(
                        color: _DarkThemeColors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                color: _DarkThemeColors.onSurfaceVariant),
            onPressed: widget.onClose,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _DarkThemeColors.background, // Darker bar for contrast
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildInfoChip('Category', _ticketData!['category'] ?? 'N/A'),
            const SizedBox(width: 12),
            _buildInfoChip('Status', _ticketData!['status'] ?? 'unknown'),
            const SizedBox(width: 12),
            _buildInfoChip('Priority', _ticketData!['priority'] ?? 'normal'),
            const SizedBox(width: 12),
            Text(
              'Created: ${_formatTimestamp(_ticketData!['createdAt'])}',
              style: TextStyle(
                  fontSize: 12, color: _DarkThemeColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    Color color;
    switch (label.toLowerCase()) {
      case 'status':
        color = _getStatusColor(value);
        break;
      case 'priority':
        color = _getPriorityColor(value);
        break;
      default:
        color = _DarkThemeColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '${label.toUpperCase()}: ${value.toUpperCase()}',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.greenAccent.shade400;
      case 'in-progress':
        return Colors.amberAccent.shade400;
      case 'closed':
        return Colors.blueGrey.shade300;
      default:
        return _DarkThemeColors.onSurfaceVariant;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return _DarkThemeColors.error;
      case 'medium':
        return Colors.orangeAccent.shade400;
      case 'low':
        return Colors.lightBlueAccent.shade400;
      default:
        return _DarkThemeColors.onSurfaceVariant;
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _DarkThemeColors.background,
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.attach_file,
                color: _isUploading
                    ? Colors.grey.shade600
                    : _DarkThemeColors.onSurfaceVariant),
            onPressed: _isUploading ? null : _sendImage,
            tooltip: 'Attach Image',
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _DarkThemeColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: _DarkThemeColors.onSurface),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Type your message...',
                    hintStyle:
                        TextStyle(color: _DarkThemeColors.onSurfaceVariant),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: _DarkThemeColors.onPrimary),
            onPressed: _isUploading
                ? null
                : () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage(text: _messageController.text.trim());
                    }
                  },
            tooltip: 'Send Message',
            style: IconButton.styleFrom(
              backgroundColor: _DarkThemeColors.primary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('MMM d, yyyy HH:mm').format(timestamp.toDate().toLocal());
  }
}

class MessageBubble extends StatelessWidget {
  final String? text;
  final String? imageUrl;
  final Timestamp? timestamp;
  final bool isFromAdmin;

  const MessageBubble({
    Key? key,
    this.text,
    this.imageUrl,
    required this.timestamp,
    required this.isFromAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alignment =
        isFromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isFromAdmin
        ? _DarkThemeColors.adminBubble
        : _DarkThemeColors.userBubble;
    final textColor = _DarkThemeColors.onPrimary;
    final timeStr = timestamp != null
        ? DateFormat('HH:mm').format(timestamp!.toDate().toLocal())
        : '';
    final bool isImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4),
            padding: isImage
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isFromAdmin ? 18 : 4),
                bottomRight: Radius.circular(isFromAdmin ? 4 : 18),
              ),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 80,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined,
                              color: _DarkThemeColors.onPrimary, size: 20)),
                    ),
                  )
                : Text(
                    text ?? '',
                    style:
                        TextStyle(color: textColor, fontSize: 15, height: 1.4),
                  ),
          ),
          const SizedBox(height: 5),
          Text(
            timeStr,
            style: TextStyle(
                fontSize: 11, color: _DarkThemeColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
