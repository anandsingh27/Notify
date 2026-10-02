import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/filter_service.dart';

class FiltersTab extends StatelessWidget {
  const FiltersTab({super.key});

  static void showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add contact / group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the exact name as it appears in WhatsApp notifications '
              '(e.g. "Mom", "Team Chat", "+91 98765 43210").',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white),
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                context.read<FilterService>().addFilter(name);
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FilterService>(
      builder: (_, fs, __) {
        return Column(
          children: [
            // ── Status banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFE8F5E9),
              child: Row(
                children: [
                  Icon(
                    fs.showAll ? Icons.all_inclusive : Icons.filter_alt_outlined,
                    size: 16,
                    color: const Color(0xFF075E54),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fs.showAll
                          ? 'Showing ALL WhatsApp messages — add a filter to narrow down.'
                          : 'Showing messages from ${fs.filters.length} '
                              'filter${fs.filters.length == 1 ? '' : 's'} only.',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF075E54), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter list ───────────────────────────────────────────
            Expanded(
              child: fs.filters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_outlined,
                              size: 68, color: Colors.grey.shade200),
                          const SizedBox(height: 14),
                          Text(
                            'No filters yet',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Tap  +  to add a contact or group name.',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: fs.filters.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 0, indent: 62, thickness: 0.5),
                      itemBuilder: (_, i) {
                        final name = fs.filters[i];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 21,
                            backgroundColor: const Color(0xFF25D366),
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                          title: Text(name,
                              style: const TextStyle(fontSize: 15)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'Remove filter',
                            onPressed: () => _confirmRemove(context, fs, name),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemove(
      BuildContext context, FilterService fs, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove filter'),
        content: Text('Remove "$name" from your filter list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              fs.removeFilter(name);
              Navigator.pop(context);
            },
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
