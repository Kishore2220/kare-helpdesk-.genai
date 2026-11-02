import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';
import 'admin_dashboard_screen.dart';
import 'chatbot_screen.dart';
import 'db_info_screen.dart';
import 'my_complaints_screen.dart';
import 'program_screens.dart';
import 'report_issue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAdmin = false;
  String _name = 'Student';
  String _reg = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  static const _categories = <(IconData, String)>[
    (Icons.school_outlined, 'Academic'),
    (Icons.bed_outlined, 'Hostel'),
    (Icons.apartment_outlined, 'Campus Blocks'),
    (Icons.directions_bus_outlined, 'Transport'),
    (Icons.local_library_outlined, 'Library'),
    (Icons.restaurant_outlined, 'Food & Canteen'),
    (Icons.edit_note_outlined, 'Examination'),
    (Icons.payments_outlined, 'Fees'),
    (Icons.local_hospital_outlined, 'Medical'),
    (Icons.build_outlined, 'Campus Complaint'),
    (Icons.theater_comedy_outlined, 'Events & Clubs'),
    (Icons.wifi, 'IT / Wi-Fi'),
  ];

  @override
  void initState() {
    super.initState();
    kIsAdmin = false;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _reg = (user.email ?? '').split('@').first.toUpperCase();
      _name = user.displayName ?? 'Student';
      _sub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snap) {
        final d = snap.data();
        if (d == null || !mounted) return;
        kIsAdmin = d['role'] == 'admin';
        setState(() {
          _isAdmin = kIsAdmin;
          _name = (d['full_name'] as String?) ?? _name;
          _reg = (d['register_number'] as String?) ?? _reg;
        });
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _screenFor(String label) {
    switch (label) {
      case 'Academic':
        return const DbInfoScreen(title: 'Academic', section: 'academic');
      case 'Hostel':
        return const DbInfoScreen(
            title: 'Hostel Help',
            section: 'hostel',
            intro: 'KARE hostels: MH1 to MH7 and L1 to L5. Tap a hostel for details.');
      case 'Campus Blocks':
        return const DbInfoScreen(
            title: 'Campus Blocks',
            section: 'blocks',
            intro: 'Main buildings of the KARE campus. Tap a block for details.');
      case 'Transport':
        return const DbInfoScreen(title: 'Transport', section: 'transport');
      case 'Library':
        return const DbInfoScreen(title: 'Central Library', section: 'library');
      case 'Food & Canteen':
        return const DbInfoScreen(
            title: 'Food & Canteen',
            section: 'canteens',
            intro: 'Campus canteens. Tap one to see details.');
      case 'Examination':
        return const DbInfoScreen(
            title: 'Examination',
            section: 'exams',
            intro: 'Exams held each semester. Dates will be added when announced.');
      case 'Fees':
        return const FeesScreen();
      case 'Medical':
        return const DbInfoScreen(title: 'Medical', section: 'medical');
      case 'Campus Complaint':
        return const ReportIssueScreen(category: 'Campus Complaint');
      case 'Events & Clubs':
        return const DbInfoScreen(title: 'Events & Clubs', section: 'events');
      default:
        return const DbInfoScreen(title: 'IT / Wi-Fi', section: 'it');
    }
  }

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Widget _action(IconData icon, String label, VoidCallback onTap, {bool filled = false}) {
    return Expanded(
      child: Material(
        color: filled ? KareColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(children: [
              Icon(icon, color: filled ? Colors.white : KareColors.blue),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, color: filled ? Colors.white : null)),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KareColors.blue,
        foregroundColor: Colors.white,
        title: const Text('KARE Help Desk'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hello, $_name 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          if (_reg.isNotEmpty) Text(_reg, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Row(children: [
            _action(Icons.report_problem_outlined, 'Report an Issue', () => _open(const ReportIssueScreen()), filled: true),
            const SizedBox(width: 10),
            _action(Icons.list_alt_outlined, 'My Complaints', () => _open(const MyComplaintsScreen())),
            if (_isAdmin) ...[
              const SizedBox(width: 10),
              _action(Icons.admin_panel_settings_outlined, 'Admin', () => _open(const AdminDashboardScreen())),
            ],
          ]),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(const ChatbotScreen()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Icon(Icons.smart_toy_outlined, color: KareColors.blue, size: 30),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ask KARE Bot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Fees, subjects, hostel, library, exams...',
                            style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final c in _categories)
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(_screenFor(c.$2)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.$1, size: 30, color: KareColors.blue),
                        const SizedBox(height: 8),
                        Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
