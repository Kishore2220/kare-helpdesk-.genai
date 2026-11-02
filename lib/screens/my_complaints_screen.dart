import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'status_chip.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('complaints')
        .where('student_id', isEqualTo: uid)
        .get();
    final rows = snap.docs.map((d) => <String, dynamic>{...d.data(), 'id': d.id}).toList();
    rows.sort((a, b) =>
        ((b['number'] as num?) ?? 0).compareTo((a['number'] as num?) ?? 0));
    return rows;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KareColors.blue,
        foregroundColor: Colors.white,
        title: const Text('My Complaints'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: TextButton(onPressed: _refresh, child: const Text('Could not load. Tap to retry.')));
          }
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No complaints yet.'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('KARE-${c['number']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            StatusChip((c['status'] as String?) ?? 'Pending'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${c['category']} - ${c['location'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text((c['description'] as String?) ?? ''),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
