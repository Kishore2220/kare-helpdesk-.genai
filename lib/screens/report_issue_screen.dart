import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

const kCategories = [
  'Hostel', 'Academic', 'Transport', 'Library', 'Food & Canteen', 'Examination',
  'Fees', 'Medical', 'Campus Complaint', 'Events & Clubs', 'IT / Wi-Fi',
];

class ReportIssueScreen extends StatefulWidget {
  final String? category;
  const ReportIssueScreen({super.key, this.category});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _location = TextEditingController();
  final _problem = TextEditingController();
  late String _category = kCategories.contains(widget.category) ? widget.category! : 'Hostel';
  XFile? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _location.dispose();
    _problem.dispose();
    super.dispose();
  }

  void _toast(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _pickPhoto() async {
    // Small, compressed photo: it is stored inside the complaint (no paid storage needed).
    final f = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 50);
    if (f != null) setState(() => _photo = f);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      String? photo;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        if (bytes.length > 700000) {
          _toast('Photo is too large. Please choose a smaller photo.');
          return;
        }
        photo = base64Encode(bytes);
      }

      final db = FirebaseFirestore.instance;
      final counter = db.collection('counters').doc('complaints');
      final number = await db.runTransaction<int>((tx) async {
        final snap = await tx.get(counter);
        final next = snap.exists ? ((snap.data()!['last'] as num).toInt() + 1) : 1024;
        tx.set(counter, {'last': next});
        tx.set(db.collection('complaints').doc('$next'), {
          'number': next,
          'student_id': user.uid,
          'student_reg': (user.email ?? '').split('@').first.toUpperCase(),
          'category': _category,
          'location': _location.text.trim(),
          'description': _problem.text.trim(),
          'image_b64': photo,
          'status': 'Pending',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
        return next;
      });

      if (!mounted) return;
      _toast('Complaint submitted: KARE-$number');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast('Could not submit. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KareColors.blue,
        foregroundColor: Colors.white,
        title: const Text('Report an Issue'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location (e.g. MH2, Academic Block 5)'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the location' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _problem,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Problem', alignLabelWithHint: true),
              validator: (v) => (v ?? '').trim().length < 5 ? 'Describe the problem' : null,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(_photo == null ? 'Upload photo (optional)' : 'Photo selected: ${_photo!.name}'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 22, width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('SUBMIT COMPLAINT'),
            ),
          ],
        ),
      ),
    );
  }
}
