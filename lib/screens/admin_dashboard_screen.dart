import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../seed_data.dart';
import '../theme.dart';
import 'status_chip.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() async {
    final snap = await FirebaseFirestore.instance.collection('complaints').get();
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

  void _toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _setStatus(String id, String status) async {
    try {
      await FirebaseFirestore.instance.collection('complaints').doc(id).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await _refresh();
    } catch (_) {
      if (mounted) _toast('Could not update. Only admins can do this.');
    }
  }

  Future<void> _seed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load starter data?'),
        content: const Text(
            'This fills the app with courses, fees, subjects, hostels, canteens and other information. '
            'Use it the first time only. It resets any edits made to that information.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Load')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await seedStarterData();
      if (mounted) _toast('Starter data loaded.');
    } catch (e) {
      if (mounted) _toast('Could not load data. Check Firestore rules and your admin role.');
    }
  }

  void _changeStatus(Map<String, dynamic> c) {
    final photo = c['image_b64'];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('KARE-${c['number']} - change status',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              if (photo is String && photo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.memory(base64Decode(photo), height: 180),
                ),
              for (final s in const ['Pending', 'In Progress', 'Resolved'])
                ListTile(
                  leading: Icon(Icons.circle, color: statusColor(s), size: 14),
                  title: Text(s),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setStatus(c['id'] as String, s);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _count(String label, int n, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border(bottom: BorderSide(color: color, width: 4)),
          ),
          child: Column(children: [
            Text('$n', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11.5)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KareColors.blue,
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Load starter data',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _seed,
          ),
        ],
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
          final all = snap.data!;
          int n(String s) => all.where((c) => c['status'] == s).length;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Row(children: [
                  _count('Total', all.length, KareColors.blue),
                  _count('Pending', n('Pending'), statusColor('Pending')),
                  _count('In Progress', n('In Progress'), statusColor('In Progress')),
                  _count('Resolved', n('Resolved'), statusColor('Resolved')),
                ]),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('Recent Complaints', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                const SizedBox(height: 8),
                if (all.isEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No complaints yet.'))),
                for (final c in all)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      onTap: () => _changeStatus(c),
                      title: Text('KARE-${c['number']}  ${c['category']}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${c['student_reg'] ?? ''} - ${c['location'] ?? ''}\n${c['description'] ?? ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      trailing: StatusChip((c['status'] as String?) ?? 'Pending'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
