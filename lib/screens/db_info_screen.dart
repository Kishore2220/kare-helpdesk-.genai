import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';
import 'program_screens.dart';
import 'report_issue_screen.dart';

/// Turns the 'action' field of an info item into a screen to open.
Widget Function(BuildContext)? actionBuilder(String? a) {
  if (a == null || a.isEmpty) return null;
  if (a.startsWith('report:')) {
    final cat = a.substring(7);
    return (_) => ReportIssueScreen(category: cat);
  }
  switch (a) {
    case 'screen:library':
      return (_) => const DbInfoScreen(title: 'Central Library', section: 'library');
    case 'screen:exams':
      return (_) => const DbInfoScreen(
          title: 'Examination',
          section: 'exams',
          intro: 'Exams held each semester. Dates will be added when announced.');
    case 'screen:fees':
      return (_) => const FeesScreen();
    case 'screen:programs':
      return (_) => const ProgramsScreen();
  }
  return null;
}

class DbInfoScreen extends StatefulWidget {
  final String title;
  final String section;
  final String? intro;
  const DbInfoScreen({super.key, required this.title, required this.section, this.intro});

  @override
  State<DbInfoScreen> createState() => _DbInfoScreenState();
}

class _DbInfoScreenState extends State<DbInfoScreen> {
  late Future<List<Map<String, dynamic>>> _future = _load();
  List<Map<String, dynamic>> _rows = [];

  Future<List<Map<String, dynamic>>> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('info_items')
        .where('section', isEqualTo: widget.section)
        .get();
    final rows = snap.docs.map((d) => <String, dynamic>{...d.data(), 'id': d.id}).toList();
    rows.sort((a, b) =>
        ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0));
    return rows;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {}
  }

  void _toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _tap(Map<String, dynamic> row) {
    final builder = actionBuilder(row['action'] as String?);
    if (builder != null) {
      Navigator.push(context, MaterialPageRoute(builder: builder));
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row['title'] as String,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text((row['details'] as String?) ?? 'Update soon. This information will be added shortly.'),
          ],
        ),
      ),
    );
  }

  String? _n(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _edit(Map<String, dynamic>? row) async {
    final title = TextEditingController(text: (row?['title'] as String?) ?? '');
    final subtitle = TextEditingController(text: (row?['subtitle'] as String?) ?? '');
    final details = TextEditingController(text: (row?['details'] as String?) ?? '');
    final group = TextEditingController(
        text: (row?['group_title'] as String?) ??
            (_rows.isNotEmpty ? (_rows.last['group_title'] as String?) ?? '' : ''));

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(row == null ? 'Add item' : 'Edit item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(
                  controller: subtitle,
                  decoration: const InputDecoration(labelText: 'Short description')),
              const SizedBox(height: 10),
              TextField(
                  controller: details,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Details (timings, menu, contacts...)', alignLabelWithHint: true)),
              const SizedBox(height: 10),
              TextField(
                  controller: group,
                  decoration: const InputDecoration(labelText: 'Group heading (optional)')),
            ],
          ),
        ),
        actions: [
          if (row != null)
            TextButton(onPressed: () => Navigator.pop(ctx, 'delete'), child: const Text('Delete')),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Save')),
        ],
      ),
    );
    if (result == null) return;

    final col = FirebaseFirestore.instance.collection('info_items');
    try {
      if (result == 'delete') {
        await col.doc(row!['id'] as String).delete();
      } else {
        if (title.text.trim().isEmpty) return;
        final data = <String, dynamic>{
          'title': title.text.trim(),
          'subtitle': _n(subtitle.text),
          'details': _n(details.text),
          'group_title': _n(group.text),
        };
        if (row == null) {
          final next = _rows.fold<int>(0, (m, r) {
                final v = ((r['sort_order'] as num?) ?? 0).toInt();
                return v > m ? v : m;
              }) +
              1;
          await col.add({...data, 'section': widget.section, 'sort_order': next});
        } else {
          await col.doc(row['id'] as String).update(data);
        }
      }
      await _refresh();
    } catch (_) {
      if (mounted) _toast('Could not save. Only admins can edit.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KareColors.blue,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      floatingActionButton: kIsAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: TextButton(onPressed: _refresh, child: const Text('Could not load. Tap to retry.')));
          }
          _rows = snap.data!;
          final groups = <String?, List<Map<String, dynamic>>>{};
          for (final r in _rows) {
            groups.putIfAbsent(r['group_title'] as String?, () => []).add(r);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                if (widget.intro != null) ...[
                  Text(widget.intro!, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 14),
                ],
                if (_rows.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Update soon.'))),
                for (final g in groups.entries) ...[
                  if (g.key != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(g.key!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  for (final r in g.value)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: KareColors.gold.withOpacity(0.25),
                          child: Icon(iconFor(r['icon'] as String?), color: KareColors.blue),
                        ),
                        title: Text(r['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: r['subtitle'] == null ? null : Text(r['subtitle'] as String),
                        trailing: kIsAdmin
                            ? IconButton(
                                icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(r))
                            : (r['details'] != null || r['action'] != null)
                                ? const Icon(Icons.chevron_right)
                                : Text('Update soon',
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                        onTap: () => _tap(r),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
