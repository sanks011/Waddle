import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../models/event_room.dart';
import '../models/chat_message.dart';

/// Show the event detail bottom sheet.
void showEventDetailModal(BuildContext context, EventRoom event) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _EventDetailSheet(event: event),
  ).then((_) => context.read<EventProvider>().closeEvent());
}

class _EventDetailSheet extends StatefulWidget {
  final EventRoom event;

  const _EventDetailSheet({required this.event});

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  late final TabController _tabCtrl;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _messageFocus = FocusNode();

  String? _passwordInput;
  bool _joiningWithPassword = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slide = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _tabCtrl = TabController(length: 2, vsync: this);
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _tabCtrl.dispose();
    _messageController.dispose();
    _scrollCtrl.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final event = context.read<EventProvider>().currentEvent;
    if (event == null) return;

    _messageController.clear();
    final success =
        await context.read<EventProvider>().sendMessage(event.id, content);
    if (success) _scrollToBottom();
  }

  Future<void> _join(EventRoom event, {String? password}) async {
    setState(() => _isJoining = true);
    final errMsg =
        await context.read<EventProvider>().joinEvent(event.id, password: password);
    setState(() {
      _isJoining = false;
      _joiningWithPassword = false;
    });
    if (errMsg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errMsg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final auth = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final currentUserId = auth.currentUser?.id ?? '';

    // Use provider-maintained current event (gets patched on join)
    final event = eventProvider.currentEvent ?? widget.event;
    final isCreator = event.creatorId == currentUserId;
    // Creator is always considered a participant (even before toSafeObject fix propagates)
    final isParticipant = isCreator || event.isParticipant(currentUserId);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slide),
      child: FadeTransition(
        opacity: _fade,
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // ── Handle + header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style:
                                        theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        event.isPublic
                                            ? Icons.public_rounded
                                            : Icons.lock_rounded,
                                        size: 12,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.45),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        event.isPublic ? 'Public' : 'Private',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.45),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('·',
                                          style:
                                              theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.3),
                                          )),
                                      const SizedBox(width: 8),
                                      Text(
                                        event.formattedExpiry,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Delete button (creator only)
                            if (isCreator)
                              IconButton(
                                onPressed: () async {
                                  final confirmed = await _showDeleteDialog();
                                  if (confirmed == true && mounted) {
                                    await context
                                        .read<EventProvider>()
                                        .deleteEvent(event.id);
                                    if (mounted) Navigator.of(context).pop();
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 22),
                                color: Colors.red.withOpacity(0.7),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tab bar
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: TabBar(
                            controller: _tabCtrl,
                            indicator: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: theme.colorScheme.onPrimary,
                            unselectedLabelColor:
                                theme.colorScheme.onSurface.withOpacity(0.5),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded,
                                        size: 16),
                                    SizedBox(width: 6),
                                    Text('Chat',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline_rounded,
                                        size: 16),
                                    SizedBox(width: 6),
                                    Text('Members',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Tab views ──
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Chat tab
                        _ChatTab(
                          event: event,
                          messages: eventProvider.messages,
                          currentUserId: currentUserId,
                          isParticipant: isParticipant,
                          scrollCtrl: _scrollCtrl,
                          messageController: _messageController,
                          messageFocus: _messageFocus,
                          isSending: eventProvider.isSendingMessage,
                          isJoining: _isJoining,
                          joiningWithPassword: _joiningWithPassword,
                          onSend: _sendMessage,
                          onJoin: () async {
                            if (!event.isPublic) {
                              setState(() => _joiningWithPassword = true);
                            } else {
                              await _join(event);
                            }
                          },
                          onPasswordSubmit: (pwd) => _join(event, password: pwd),
                          onPasswordCancel: () =>
                              setState(() => _joiningWithPassword = false),
                        ),
                        // Members tab
                        _MembersTab(
                          event: event,
                          currentUserId: currentUserId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'This will remove the event and all messages. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Chat tab ─────────────────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  final EventRoom event;
  final List<ChatMessage> messages;
  final String currentUserId;
  final bool isParticipant;
  final ScrollController scrollCtrl;
  final TextEditingController messageController;
  final FocusNode messageFocus;
  final bool isSending;
  final bool isJoining;
  final bool joiningWithPassword;
  final VoidCallback onSend;
  final VoidCallback onJoin;
  final ValueChanged<String> onPasswordSubmit;
  final VoidCallback onPasswordCancel;

  const _ChatTab({
    required this.event,
    required this.messages,
    required this.currentUserId,
    required this.isParticipant,
    required this.scrollCtrl,
    required this.messageController,
    required this.messageFocus,
    required this.isSending,
    required this.isJoining,
    required this.joiningWithPassword,
    required this.onSend,
    required this.onJoin,
    required this.onPasswordSubmit,
    required this.onPasswordCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (!isParticipant) {
      // Join prompt
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_rounded,
              size: 56,
              color: primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Join to see the chat',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.description.isNotEmpty
                  ? event.description
                  : 'Connect with others at this event',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Password input for private rooms
            if (joiningWithPassword) ...[
              _PasswordJoinField(
                onSubmit: onPasswordSubmit,
                onCancel: onPasswordCancel,
              ),
            ] else ...[
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: isJoining ? null : onJoin,
                  icon: isJoining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          event.isPublic
                              ? Icons.login_rounded
                              : Icons.lock_open_rounded,
                          size: 18,
                        ),
                  label: Text(event.isPublic ? 'Join Room' : 'Enter Password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Participant view: chat messages + input
    return Column(
      children: [
        // Messages list
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet. Say hi!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isOwn = msg.userId == currentUserId;
                    return _MessageBubble(
                      message: msg,
                      isOwn: isOwn,
                      index: i,
                    );
                  },
                ),
        ),

        // Message input
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: TextField(
                    controller: messageController,
                    focusNode: messageFocus,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isSending ? null : onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSending
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwn;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index % 10) * 30),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (ctx, value, child) {
        return Transform.translate(
          offset: Offset(isOwn ? 16 * (1 - value) : -16 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isOwn)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    message.username,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isOwn ? primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        isOwn ? const Radius.circular(18) : const Radius.circular(4),
                    bottomRight:
                        isOwn ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                  border: isOwn
                      ? null
                      : Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isOwn
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Members tab ───────────────────────────────────────────────────────────────

class _MembersTab extends StatelessWidget {
  final EventRoom event;
  final String currentUserId;

  const _MembersTab({required this.event, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: event.participants.length,
      itemBuilder: (ctx, i) {
        final p = event.participants[i];
        final isCreator = p.userId == event.creatorId;
        final isYou = p.userId == currentUserId;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + i * 40),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (ctx, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isYou
                  ? primary.withOpacity(0.07)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isYou ? primary.withOpacity(0.25) : theme.dividerColor,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primary.withOpacity(0.15),
                  child: Text(
                    p.username.isNotEmpty
                        ? p.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            p.username,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isCreator) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Host',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          if (isYou) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Password join field ───────────────────────────────────────────────────────

class _PasswordJoinField extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback onCancel;

  const _PasswordJoinField({required this.onSubmit, required this.onCancel});

  @override
  State<_PasswordJoinField> createState() => _PasswordJoinFieldState();
}

class _PasswordJoinFieldState extends State<_PasswordJoinField> {
  final _ctrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            controller: _ctrl,
            obscureText: _obscure,
            autofocus: true,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Enter room password',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onSubmit(_ctrl.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Join'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
