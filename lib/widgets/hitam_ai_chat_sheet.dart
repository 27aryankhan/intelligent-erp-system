import 'package:flutter/material.dart';
import '../services/hitam_ai_service.dart';
import '../services/database_service.dart';
import '../services/hitam_auth_service.dart';
import '../services/hitam_scraper_service.dart';

/// Interactive Chat Sheet for the Domain-Trained HITAM Campus AI Assistant
class HitamAiChatSheet extends StatefulWidget {
  final String? initialRollNo;
  final String? role;

  const HitamAiChatSheet({
    super.key,
    this.initialRollNo,
    this.role,
  });

  static void show(BuildContext context, {String? rollNo, String? role}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HitamAiChatSheet(initialRollNo: rollNo, role: role),
    );
  }

  @override
  State<HitamAiChatSheet> createState() => _HitamAiChatSheetState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class _HitamAiChatSheetState extends State<HitamAiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  List<SubjectAttendance> _cachedAttendance = [];

  @override
  void initState() {
    super.initState();
    _loadContextAndGreet();
  }

  Future<void> _loadContextAndGreet() async {
    final userId = widget.initialRollNo ??
        HitamAuthService().activeUserId ??
        '';

    // Retrieve cached attendance from SQLite for context injection
    final records = await DatabaseService().getCachedAttendance(userId);
    if (mounted) {
      setState(() {
        _cachedAttendance = records;
        _messages.add(
          _ChatMessage(
            isUser: false,
            text: '''
👋 **Welcome to HITAM AI Advisor!**
I am your campus intelligent assistant trained on HITAM academic regulations (HR21/HR22/HR24).

${records.isNotEmpty ? "I have loaded your **${records.length} subjects** from Webpros." : "Log in to Webpros to view live personalized calculations."}

Ask me anything or tap a shortcut below!
''',
          ),
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    final userId = widget.initialRollNo ??
        HitamAuthService().activeUserId ??
        'Student';
    final role = widget.role ?? HitamAuthService().activeRole?.name ?? 'student';

    final reply = await HitamAiService().ask(
      query: query,
      attendance: _cachedAttendance,
      role: role,
      rollNo: userId,
    );

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF101827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0x331F8941),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1F8941), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.psychology, color: Color(0xFF40A047), size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HITAM Campus AI Advisor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Trained on HR21/HR22/HR24 Regulations',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Shortcut Suggestion Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildQuickChip('🎯 Safe Bunks', 'Can I bunk any class today?'),
                _buildQuickChip('📊 Full Status', 'Give me my full attendance status'),
                _buildQuickChip('⚠️ Recovery Plan', 'How many classes do I need to attend to reach 75%?'),
                _buildQuickChip('📜 Condonation Rules', 'What are HITAM condonation and detention rules?'),
              ],
            ),
          ),

          // Message Feed
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment:
                      msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: msg.isUser
                          ? const Color(0xFF1F8941)
                          : const Color(0xFF1F2937),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF40A047)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'HITAM AI is thinking...',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              border: Border(top: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask about attendance, bunks, exams...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8941),
                  ),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF374151)),
        ),
        onPressed: () => _sendMessage(prompt),
      ),
    );
  }
}
