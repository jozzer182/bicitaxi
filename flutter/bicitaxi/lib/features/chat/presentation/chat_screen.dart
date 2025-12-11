import 'package:flutter/material.dart';
import 'package:liquid_glass_ui_design/liquid_glass_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/glass_container.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message.dart';
import '../repository/chat_repository.dart';

/// Chat screen for ride conversations.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.rideId,
    required this.chatRepo,
    required this.currentUserId,
    required this.isClientApp,
    this.participantName,
  });

  final String rideId;
  final ChatRepository chatRepo;
  final String currentUserId;
  final bool isClientApp;
  final String? participantName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController _controller;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      repo: widget.chatRepo,
      rideId: widget.rideId,
      currentUserId: widget.currentUserId,
      isClientApp: widget.isClientApp,
    );
    _controller.init();
    _controller.addListener(_onMessagesChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onMessagesChanged);
    _controller.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onMessagesChanged() {
    setState(() {});
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    await _controller.sendText(text);

    // Simulate a reply for demo purposes
    _controller.simulateRemoteReply();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveUtils.isTabletOrLarger(context);
    final participantName =
        widget.participantName ??
        (widget.isClientApp ? 'Conductor' : 'Pasajero');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(context, participantName),

            // Messages
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 600 : double.infinity,
                  ),
                  child: _buildMessageList(context),
                ),
              ),
            ),

            // Input bar
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : double.infinity,
                ),
                child: _buildInputBar(context, isTablet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String participantName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: UltraGlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: UltraGlassCard(
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.electricBlue.withValues(
                      alpha: 0.2,
                    ),
                    child: Icon(
                      widget.isClientApp
                          ? Icons.directions_bike_rounded
                          : Icons.person_rounded,
                      color: AppColors.electricBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          participantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Chat del viaje',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    if (_controller.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppColors.steelBlue.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin mensajes aún',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Envía un mensaje para iniciar la conversación',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _controller.messages.length,
      itemBuilder: (context, index) {
        final message = _controller.messages[index];
        final isMe = message.senderId == widget.currentUserId;
        final showTimestamp =
            index == 0 ||
            _shouldShowTimestamp(_controller.messages[index - 1], message);

        return _buildMessageBubble(context, message, isMe, showTimestamp);
      },
    );
  }

  bool _shouldShowTimestamp(ChatMessage previous, ChatMessage current) {
    return current.sentAt.difference(previous.sentAt).inMinutes > 5;
  }

  Widget _buildMessageBubble(
    BuildContext context,
    ChatMessage message,
    bool isMe,
    bool showTimestamp,
  ) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                _formatTimestamp(message.sentAt),
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (isMe) const Spacer(flex: 1),
              Flexible(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.electricBlue
                        : AppColors.surfaceMedium,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          color: isMe ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.sentAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? AppColors.white.withValues(alpha: 0.7)
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isMe) const Spacer(flex: 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: UltraGlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      return 'Hoy, ${_formatTime(dateTime)}';
    } else if (diff.inDays == 1) {
      return 'Ayer, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
