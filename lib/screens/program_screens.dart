import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';

Future<List<Map<String, dynamic>>> _loadPrograms() async {
  final snap = await FirebaseFirestore.instance.collection('programs').get();
  final rows = snap.docs.map((d) => <String, dynamic>{...d.data(), 'id': d.id}).toList();
  rows.sort((a, b) =>
      ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0));
  return rows;
}

PreferredSizeWidget _bar(String t) => AppBar(
      backgroundColor: KareColors.blue,
      foregroundColor: Colors.white,
      title: Text(t),
    );

Widget _tile(IconData icon, String title, String? subtitle, {Widget? trailing, VoidCallback? onTap}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: KareColors.gold.withOpacity(0.25),
        child: Icon(icon, color: KareColors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

Widget _emptyHint() => const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text('No courses yet. An admin must open Admin > "Load starter data" once.',
            textAlign: TextAlign.center),
      ),
    );

// ---------------- Courses & Subjects ----------------
class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar('Courses & Subjects'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadPrograms(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return const Center(child: Text('Could not load. Check internet.'));
          final list = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Tap a course to see its subjects year by year.',
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              if (list.isEmpty) _emptyHint(),
              for (final p in list)
                _tile(Icons.school_outlined, p['name'] as String, '${p['years']} years',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ProgramDetailScreen(p)))),
            ],
          );
        },
      ),
    );
  }
}

class ProgramDetailScreen extends StatelessWidget {
  final Map<String, dynamic> program;
  const ProgramDetailScreen(this.program, {super.key});

  @override
  Widget build(BuildContext context) {
    final raw = (program['subjects'] as Map?) ?? {};
    final years = raw.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

    return Scaffold(
      appBar: _bar('Subjects & Fees'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(program['name'] as String,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(padding: const EdgeInsets.all(14), child: Text(feeText(program))),
          ),
          const SizedBox(height: 14),
          const Text('Subjects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final y in years)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                shape: const Border(),
                title: Text('Year $y', style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  for (final s in (raw[y] as List))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.menu_book_outlined, size: 18),
                      title: Text(s.toString()),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'These are typical subjects for this branch. Your exact subject list depends on your regulation - check with your department.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ---------------- Fees ----------------
class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  late Future<List<Map<String, dynamic>>> _future = _loadPrograms();

  void _reload() => setState(() => _future = _loadPrograms());

  void _show(Map<String, dynamic> p) {
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
            Text(p['name'] as String,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(feeText(p)),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(Map<String, dynamic> p) async {
    final t = TextEditingController(text: '${p['tuition']}');
    final o = TextEditingController(text: '${p['other_fee']}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p['name'] as String, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: t,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Annual tuition fee (₹)')),
            const SizedBox(height: 10),
            TextField(
                controller: o,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Other fees per year (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final tv = int.tryParse(t.text.trim());
    final ov = int.tryParse(o.text.trim());
    if (tv == null || ov == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('programs')
          .doc(p['id'] as String)
          .update({'tuition': tv, 'other_fee': ov});
      _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _bar('Fees'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return const Center(child: Text('Could not load. Check internet.'));
          final list = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                  'Fees for 2026-27 from the KARE fee page (resident Indian students, before scholarship). Tap a course for the full breakdown.',
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              if (list.isEmpty) _emptyHint(),
              for (final p in list)
                _tile(
                  Icons.payments_outlined,
                  p['name'] as String,
                  'Tuition ${inr((p['tuition'] as num).toInt())} per year',
                  trailing: kIsAdmin
                      ? IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(p))
                      : null,
                  onTap: () => _show(p),
                ),
            ],
          );
        },
      ),
    );
  }
}
