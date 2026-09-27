import 'package:flutter/material.dart';
import '../services/ai_assistant_service.dart';

class AIAssistantSheet extends StatefulWidget {
  /// Optional CAREX patient context.
  ///
  /// Pass this when opening the assistant if you have patient/exercise
  /// information available.
  final CAREXContext? carexContext;

  const AIAssistantSheet({
    Key? key,
    this.carexContext,
  }) : super(key: key);

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final AIAssistantService _aiService = AIAssistantService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  bool _isTyping = false;

  final List<String> _quickPrompts = [
    'How is my progress?',
    'Why was my rep not counted?',
    'How can I improve my form?',
    'What exercise should I focus on?',
    'Give me posture tips',
    'Explain my exercise',
  ];

  @override
  void initState() {
    super.initState();

    _messages.add(
      ChatMessage(
        text: _buildWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  String _buildWelcomeMessage() {
    if (widget.carexContext?.currentExercise != null) {
      return '''
Hi! I'm CAREX AI 👋

I'm here to help you with your rehabilitation, exercise technique, posture and progress.

I can currently help you understand your ${widget.carexContext!.currentExercise} session.

Ask me about your reps, form, progress or exercise technique.
''';
    }

    return '''
Hi! I'm CAREX AI 👋

I'm your rehabilitation assistant.

I can help you with:

• Exercise technique
• Repetition and form feedback
• Rehabilitation progress
• Posture guidance
• Exercise intensity
• Readiness and mood
• Heart rate and SpO₂ information

What would you like help with?
''';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();

    if (query.isEmpty || _isTyping) {
      return;
    }

    final userMessage = ChatMessage(
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _controller.clear();

    await _scrollToBottom();

    try {
      final responseText = await _aiService.getResponse(
        query,
        carexContext: widget.carexContext,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: responseText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );

        _isTyping = false;
      });

      await _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTyping = false;

        _messages.add(
          ChatMessage(
            text:
                'I could not process that request right now. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });

      await _scrollToBottom();
    }
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 50));

    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _clearConversation() {
    if (_isTyping) {
      return;
    }

    _aiService.clearConversation();

    setState(() {
      _messages.clear();

      _messages.add(
        ChatMessage(
          text: _buildWelcomeMessage(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _showClearChatConfirmation() {
    if (_isTyping) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Clear conversation?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This will remove the current conversation from CAREX AI.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _clearConversation();
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildQuickPrompts(),
          const Divider(
            color: Colors.white10,
            height: 1,
          ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];

                      return _buildBubble(message);
                    },
                  ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypingIndicator(),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        12,
        10,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.tealAccent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.tealAccent.withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.tealAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAREX AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Rehabilitation Assistant',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: _showClearChatConfirmation,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white54,
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: const Color(0xFF1E293B),
              side: BorderSide(
                color: Colors.tealAccent.withOpacity(0.15),
              ),
              label: Text(
                prompt,
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: _isTyping
                  ? null
                  : () => _sendMessage(prompt),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.tealAccent,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'How can I help with your recovery?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me about exercises, posture, form, repetitions or progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        14,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          top: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isTyping,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask CAREX AI...',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.tealAccent.withOpacity(0.35),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isTyping
                    ? Colors.white12
                    : Colors.tealAccent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                tooltip: 'Send',
                onPressed: _isTyping
                    ? null
                    : () => _sendMessage(_controller.text),
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: _isTyping
                      ? Colors.white38
                      : const Color(0xFF0F172A),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF2563EB)
              : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser
                ? Radius.zero
                : const Radius.circular(18),
            bottomLeft: !isUser
                ? Radius.zero
                : const Radius.circular(18),
          ),
          border: Border.all(
            color: isUser
                ? Colors.transparent
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.tealAccent,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'CAREX AI',
                      style: TextStyle(
                        color: Colors.tealAccent.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState
    extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.tealAccent,
              size: 13,
            ),
            const SizedBox(width: 7),
            const Text(
              'CAREX AI',
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 7),
            _dot(0, value),
            _dot(1, value),
            _dot(2, value),
          ],
        );
      },
    );
  }

  Widget _dot(
    int index,
    double animationValue,
  ) {
    final phase =
        (animationValue * 3 - index).clamp(0.0, 1.0);

    final opacity = 0.35 + (phase * 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      child: Opacity(
        opacity: opacity,
        child: const Text(
          '•',
          style: TextStyle(
            color: Colors.tealAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}