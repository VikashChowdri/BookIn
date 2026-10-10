import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../models/message.dart';
import '../../models/user_model.dart';
import '../../models/book.dart';
import '../../routes/app_routes.dart';

class ChatDetailScreen extends StatefulWidget {
  final String roomId;
  final UserModel otherUser;
  final Book? contextBook;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.otherUser,
    this.contextBook,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.instance;
  final String _currentUserId = AuthService.instance.currentUser?.uid ?? '';
  bool _showContextBanner = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _chatService.markAsRead(widget.roomId);
    if (widget.contextBook != null) {
      _showContextBanner = true;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && !_showContextBanner) return;

    final attachedId = _showContextBanner ? widget.contextBook?.id : null;
    final attachedTitle = _showContextBanner ? widget.contextBook?.title : null;
    final attachedImage = _showContextBanner && widget.contextBook!.imageUrl.isNotEmpty 
        ? widget.contextBook!.imageUrl 
        : null;

    _messageController.clear();
    setState(() {
      _showContextBanner = false;
    });

    await _chatService.sendMessage(
      widget.roomId, 
      widget.otherUser.id, 
      text,
      attachedBookId: attachedId,
      attachedBookTitle: attachedTitle,
      attachedBookImageUrl: attachedImage,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.roomId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await _chatService.sendMessage(
        widget.roomId,
        widget.otherUser.id,
        '',
        chatImageUrl: downloadUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = widget.otherUser.profilePictureUrl.isNotEmpty &&
        !widget.otherUser.profilePictureUrl.contains('unsplash');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.publicProfile,
              arguments: widget.otherUser,
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                backgroundImage: hasImage ? CachedNetworkImageProvider(widget.otherUser.profilePictureUrl) : null,
                child: !hasImage
                    ? Icon(Icons.person, size: 20, color: theme.colorScheme.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.otherUser.publicName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getChatMessages(widget.roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }

                // Mark as read whenever new messages arrive and we're looking at them
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _chatService.markAsRead(widget.roomId);
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8, top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                            bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                          ),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.attachedBookId != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.white.withValues(alpha: 0.2) : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (message.attachedBookImageUrl != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CachedNetworkImage(
                                          imageUrl: message.attachedBookImageUrl!,
                                          width: 32,
                                          height: 48,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        message.attachedBookTitle ?? 'Book',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (message.chatImageUrl != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: message.chatImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const SizedBox(
                                      height: 150,
                                      child: Center(child: CircularProgressIndicator()),
                                    ),
                                  ),
                                ),
                              ),
                            if (message.text.isNotEmpty)
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : theme.colorScheme.onSurface,
                                  fontSize: 15,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Context Banner
          if (_showContextBanner && widget.contextBook != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Row(
                children: [
                  if (widget.contextBook!.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: widget.contextBook!.imageUrl,
                        width: 32,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inquiring about:',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.contextBook!.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      setState(() {
                        _showContextBanner = false;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  color: theme.colorScheme.primary,
                  onPressed: _isUploadingImage ? null : _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isUploadingImage)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
