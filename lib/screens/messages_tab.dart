import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wa_message.dart';
import '../services/notification_service.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  static const _avatarColors = [
    Color(0xFF1ABC9C), Color(0xFF2ECC71), Color(0xFF3498DB),
    Color(0xFF9B59B6), Color(0xFFE67E22), Color(0xFFE74C3C),
    Color(0xFF16A085), Color(0xFF8E44AD), Color(0xFF2980B9),
  ];

  static Color _colorFor(String s) =>
      _avatarColors[s.isEmpty ? 0 : s.codeUnitAt(0) % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (_, ns, __) {
        final msgs = ns.messages;

        if (msgs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No filtered messages yet',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  'Messages from your selected contacts\nwill appear here in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Unread banner
            if (ns.unreadCount > 0)
              Material(
                color: const Color(0xFF25D366),
                child: InkWell(
                  onTap: ns.markAllRead,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_chat_read_outlined,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${ns.unreadCount} unread message${ns.unreadCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                        const Text('Mark all read',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),

            // Message list
            Expanded(
              child: ListView.separated(
                itemCount: msgs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 0, indent: 72, thickness: 0.5),
                itemBuilder: (_, i) => _MessageRow(msg: msgs[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  final WaMessage msg;
  const _MessageRow({required this.msg});

  static const _avatarColors = [
    Color(0xFF1ABC9C), Color(0xFF2ECC71), Color(0xFF3498DB),
    Color(0xFF9B59B6), Color(0xFFE67E22), Color(0xFFE74C3C),
    Color(0xFF16A085), Color(0xFF8E44AD), Color(0xFF2980B9),
  ];

  Color get _color => _avatarColors[
      msg.sender.isEmpty ? 0 : msg.sender.codeUnitAt(0) % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final isUnread = !msg.isRead;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _color,
        child: Text(
          msg.sender.isEmpty ? '?' : msg.sender[0].toUpperCase(),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              msg.sender,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            msg.timeLabel,
            style: TextStyle(
              color: isUnread ? const Color(0xFF25D366) : Colors.grey,
              fontSize: 12,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          msg.text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: isUnread ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
      trailing: isUnread
          ? const CircleAvatar(
              radius: 5,
              backgroundColor: Color(0xFF25D366),
            )
          : null,
    );
  }
}
