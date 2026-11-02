import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils.dart';

/// KARE FAQ bot. No AI service is used: it reads the same information
/// pages and courses that the app already stores in Firestore and finds
/// the best match for the words in the question. When an admin edits an
/// information page, the bot answers with the new text automatically.

// ---------------------------------------------------------------- words

const _stop = <String>{
  'a', 'an', 'the', 'is', 'are', 'was', 'am', 'i', 'me', 'my', 'you', 'your',
  'what', 'whats', 'where', 'which', 'who', 'when', 'how', 'do', 'does', 'did',
  'can', 'could', 'please', 'pls', 'tell', 'about', 'give', 'show', 'to', 'of',
  'in', 'on', 'at', 'for', 'and', 'or', 'there', 'any', 'have', 'has', 'get',
  'want', 'need', 'know', 'info', 'information', 'details', 'detail', 'kare',
  'college', 'it', 'its', 'this', 'that', 'with', 'from', 'be', 'available',
  'will', 'should', 'our', 'we', 'us', 'some', 'all',
};

const _syn = <String, String>{
  'tuition': 'fee',
  'cost': 'fee',
  'price': 'fee',
  'charge': 'fee',
  'payment': 'fee',
  'amount': 'fee',
  'time': 'timing',
  'schedule': 'timing',
  'hour': 'timing',
  'hours': 'timing',
  'open': 'timing',
  'opening': 'timing',
  'close': 'timing',
  'closing': 'timing',
  'internet': 'wifi',
  'buses': 'bus',
  'eat': 'food',
  'lunch': 'food',
  'dinner': 'food',
  'breakfast': 'food',
  'snack': 'food',
  'hungry': 'food',
  'examination': 'exam',
  'syllabus': 'subject',
  'curriculum': 'subject',
  'clinic': 'medical',
};

const _generic = <String>{'tech', 'engineering', 'and'};

const _aliasText = <String, String>{
  'academic': 'academic course subject calendar regulation attendance department faculty office',
  'hostel': 'hostel room mess laundry wifi water warden rule',
  'blocks': 'block building campus',
  'transport': 'transport bus route boarding',
  'library': 'library book thesis project report competitive',
  'canteens': 'canteen food menu',
  'exams': 'exam practical semester result registration',
  'medical': 'medical hospital doctor ambulance emergency health',
  'events': 'event club sport',
  'it': 'wifi internet computer lab',
};

/// Splits text into simple lower-case words (same rules for questions and
/// for the stored information, so they can be compared).
List<String> _tokens(String text, {bool dropStop = false}) {
  final t = text
      .toLowerCase()
      .replaceAll(RegExp(r'wi[\s-]?fi'), 'wifi')
      .replaceAll('timetable', 'time table')
      .replaceAll('&', ' and ');
  final out = <String>[];
  for (var w in t.split(RegExp(r'[^a-z0-9]+'))) {
    if (w.isEmpty) continue;
    if (dropStop && _stop.contains(w)) continue;
    w = _syn[w] ?? w;
    if (w.length > 3 && w.endsWith('s') && !w.endsWith('ss')) {
      w = w.substring(0, w.length - 1);
    }
    w = _syn[w] ?? w;
    if (w.length < 2 && !RegExp(r'^[0-9]$').hasMatch(w)) continue;
    out.add(w);
  }
  return out;
}

// ---------------------------------------------------------------- data

class _Doc {
  final String section;
  final String title;
  final String answer;
  final Set<String> titleWords;
  final Set<String> otherWords;
  _Doc(this.section, this.title, this.answer, this.titleWords, this.otherWords);
}

class _Prog {
  final Map<String, dynamic> data;
  _Prog(this.data);

  String get name => (data['name'] as String?) ?? '';

  /// "CSE" for "B.Tech Computer Science & Engineering (CSE)"
  String get short {
    final m = RegExp(r'\(([^)]+)\)').firstMatch(name);
    if (m != null) return m.group(1)!;
    return name.replaceFirst('B.Tech ', '');
  }
}

class _Chip {
  final String label;
  final String query;
  const _Chip(this.label, this.query);
}

class _Reply {
  final String text;
  final List<_Chip> chips;
  const _Reply(this.text, [this.chips = const []]);
}

class _Msg {
  final bool fromUser;
  final String text;
  final List<_Chip> chips;
  _Msg(this.fromUser, this.text, [this.chips = const []]);
}

class _Hit {
  final _Doc doc;
  final int score;
  final int index;
  _Hit(this.doc, this.score, this.index);
}

const _starterChips = <_Chip>[
  _Chip('CSE fees', 'CSE fees'),
  _Chip('Library timings', 'Library timings'),
  _Chip('Hostel rules', 'Hostel rules'),
  _Chip('Canteens', 'Canteen'),
  _Chip('Exams', 'Exam'),
  _Chip('Medical', 'Medical'),
  _Chip('Bus routes', 'Bus routes'),
  _Chip('Report an issue', 'Report an issue'),
];

// ---------------------------------------------------------------- screen

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  final List<_Doc> _docs = [];
  final List<_Prog> _progs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
        false,
        'Hi! I am the KARE Help Desk bot. Ask me about fees, subjects, hostels, '
        'canteens, library, exams, campus blocks, medical help or buses.\n\n'
        'Example: "CSE fees", "library timings", "MH3" or "Nalabagam canteen".',
        _starterChips));
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final infoSnap = await db.collection('info_items').get();
      final progSnap = await db.collection('programs').get();

      final items = infoSnap.docs.map((d) => d.data()).toList();
      items.sort((a, b) =>
          ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0));
      final progs = progSnap.docs.map((d) => d.data()).toList();
      progs.sort((a, b) =>
          ((a['sort_order'] as num?) ?? 0).compareTo((b['sort_order'] as num?) ?? 0));

      for (final r in items) {
        final doc = _docFrom(r);
        if (doc != null) _docs.add(doc);
      }
      for (final p in progs) {
        _progs.add(_Prog(p));
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load the information. Check your internet and open the bot again.';
        });
      }
    }
  }

  _Doc? _docFrom(Map<String, dynamic> r) {
    final title = ((r['title'] as String?) ?? '').trim();
    if (title.isEmpty) return null;
    final action = (r['action'] as String?) ?? '';
    if (action.startsWith('screen:')) return null; // just a shortcut, no text
    final section = (r['section'] as String?) ?? '';
    final subtitle = ((r['subtitle'] as String?) ?? '').trim();
    final group = ((r['group_title'] as String?) ?? '').trim();
    final details = ((r['details'] as String?) ?? '').trim();

    String answer;
    if (action.startsWith('report:')) {
      final cat = action.substring(7);
      answer = '$title\n\nOn the home screen tap "Report an Issue" and choose the '
          '"$cat" category. Your complaint gets a KARE number and you can follow '
          'its status in "My Complaints".';
    } else if (details.isNotEmpty) {
      answer = '$title\n\n$details';
    } else if (subtitle.isNotEmpty) {
      answer = '$title: $subtitle\n\nMore details: Update soon. This information will be added shortly.';
    } else {
      answer = '$title\n\nUpdate soon. This information will be added shortly.';
    }

    return _Doc(
      section,
      title,
      answer,
      _tokens(title).toSet(),
      _tokens('$subtitle $group $details').toSet(),
    );
  }

  // ------------------------------------------------------------ answering

  int _score(Set<String> q, _Doc d) {
    var s = 0;
    final alias = _tokens(_aliasText[d.section] ?? '').toSet();
    for (final w in q) {
      if (d.titleWords.contains(w)) {
        s += 3;
      } else if (d.otherWords.contains(w)) {
        s += 1;
      }
      if (alias.contains(w)) s += 1;
    }
    return s;
  }

  int _progScore(_Prog p, Set<String> q, String compact) {
    var s = 0;
    final ab = p.short.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (ab.length >= 3) {
      final t = _tokens(ab);
      final typedAbbr = t.isNotEmpty && q.contains(t.first);
      final typedCompact = ab.length >= 4 && compact.contains(ab);
      if (typedAbbr || typedCompact) s += 5;
    }
    for (final w in _tokens(p.name)) {
      if (_generic.contains(w)) continue;
      if (q.contains(w)) s += 1;
    }
    return s;
  }

  int? _yearIn(String low) {
    const words = {
      '1st': 1, 'first': 1, '2nd': 2, 'second': 2,
      '3rd': 3, 'third': 3, '4th': 4, 'fourth': 4,
    };
    for (final e in words.entries) {
      if (RegExp('\\b${e.key}\\b').hasMatch(low)) return e.value;
    }
    final m = RegExp(r'year\s*([1-4])\b|\b([1-4])\s*year').firstMatch(low);
    if (m != null) return int.parse(m.group(1) ?? m.group(2)!);
    return null;
  }

  String _subjectsText(_Prog p, int? year) {
    final raw = (p.data['subjects'] as Map?) ?? {};
    final years = raw.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    String line(String y) {
      final v = raw[y];
      final list = v is List ? v.map((e) => e.toString()).toList() : <String>[];
      return 'Year $y: ${list.isEmpty ? "Update soon" : list.join(", ")}';
    }

    final b = StringBuffer('Subjects for ${p.name}\n\n');
    if (year != null) {
      b.writeln(raw.containsKey('$year') ? line('$year') : 'Year $year: Update soon');
    } else {
      for (final y in years) {
        b.writeln(line(y));
        b.writeln();
      }
    }
    b.write('These are typical subjects for this branch. Your exact list depends on '
        'your regulation, so check with your department.');
    return b.toString();
  }

  List<_Chip> _courseChips(String suffix) => [
        for (final p in _progs) _Chip(p.short, '${p.name} $suffix'),
      ];

  _Reply _listReply(String heading, List<_Hit> hits) => _Reply(
        heading,
        [for (final h in hits) _Chip(h.doc.title, h.doc.title)],
      );

  _Reply _answer(String raw) {
    if (_error != null) return _Reply(_error!);
    if (_loading) return const _Reply('Still loading the information. Please try again in a moment.');
    if (_docs.isEmpty && _progs.isEmpty) {
      return const _Reply(
          'No information has been loaded yet. Ask an admin to open Admin and press '
          '"Load starter data".');
    }

    final low = raw.toLowerCase();
    final q = _tokens(raw, dropStop: true).toSet();

    if (RegExp(r'^\s*(hi+|hello+|hey+|hai+|hlo|good\s*(morning|afternoon|evening))\b')
            .hasMatch(low) &&
        q.length <= 1) {
      return const _Reply('Hello! What would you like to know?', _starterChips);
    }
    if (low.contains('thank')) {
      return const _Reply('You are welcome! Ask me anything else about KARE.', _starterChips);
    }
    if (q.isEmpty) {
      return const _Reply('Please type a question, for example "CSE fees" or "library timings".', _starterChips);
    }
    if (q.length == 1 && q.contains('help')) {
      return const _Reply(
          'I can answer questions about fees, course subjects, hostels (MH1-MH7, L1-L5), '
          'canteens, campus blocks, library, exams, medical help and buses.\n\n'
          'To report a problem, use "Report an Issue" on the home screen.',
          _starterChips);
    }

    // complaints
    final complaintWords = q.contains('complaint') ||
        (q.contains('report') && q.contains('issue')) ||
        q.contains('raise');
    if (complaintWords && !q.contains('project') && !q.contains('thesis')) {
      final status = low.contains('status') || low.contains('track') || low.contains('my complaint');
      return _Reply(status
          ? 'Open "My Complaints" on the home screen to see every complaint you sent and its '
              'status (Pending, In Progress or Resolved).'
          : 'To report a problem, tap "Report an Issue" on the home screen, choose a category, '
              'describe the problem, add a photo if you like and press Submit. You will get a '
              'KARE number such as KARE-1024.');
    }

    // courses, fees, subjects
    final wantsFee = q.contains('fee');
    final wantsSub = q.contains('subject');
    final wantsCourse = q.contains('course') || q.contains('branch') || q.contains('program');

    if (wantsFee && (q.contains('hostel') || q.contains('mess'))) {
      return const _Reply(
          'Hostel and mess fees are extra and are not added to the app yet. Update soon. '
          'Please ask the Accounts Office.');
    }

    var best = 0;
    final scores = <int>[];
    if (_progs.isNotEmpty) {
      final compact = low.replaceAll(RegExp(r'[^a-z0-9]'), '');
      for (final p in _progs) {
        final s = _progScore(p, q, compact);
        scores.add(s);
        if (s > best) best = s;
      }
      if (wantsFee || wantsSub || wantsCourse || best >= 5) {
        if (best > 0) {
          final matches = <_Prog>[
            for (var i = 0; i < _progs.length; i++)
              if (scores[i] == best) _progs[i],
          ];
          final suffix = wantsSub ? 'subjects' : 'fee';
          if (matches.length > 1) {
            return _Reply('Which course do you mean?', [
              for (final p in matches) _Chip(p.short, '${p.name} $suffix'),
            ]);
          }
          final p = matches.first;
          if (wantsSub) return _Reply(_subjectsText(p, _yearIn(low)));
          return _Reply(
              '${p.name}\n\n${feeText(p.data)}',
              [_Chip('${p.short} subjects', '${p.name} subjects')]);
        }
        // no course named
        final names = _progs.map((p) => p.short).join(', ');
        if (wantsSub) {
          return _Reply('Which course? For example "CSE subjects".\n\nCourses: $names',
              _courseChips('subjects'));
        }
        if (wantsFee) {
          return _Reply('Which course? For example "CSE fees".\n\nCourses: $names',
              _courseChips('fee'));
        }
        return _Reply('Courses in this app: $names\n\nTap one for its fees, or ask '
            '"<course> subjects".', _courseChips('fee'));
      }
    }

    // information pages
    final scored = <_Hit>[];
    for (var i = 0; i < _docs.length; i++) {
      final s = _score(q, _docs[i]);
      if (s > 0) scored.add(_Hit(_docs[i], s, i));
    }
    scored.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.index.compareTo(b.index);
    });

    // a course named on its own, for example "mechanical"
    _Reply? courseOnly() {
      if (best <= 0) return null;
      final matches = <_Prog>[
        for (var i = 0; i < _progs.length; i++)
          if (scores[i] == best) _progs[i],
      ];
      if (matches.length != 1) return null;
      final p = matches.first;
      return _Reply('${p.name}\n\n${feeText(p.data)}',
          [_Chip('${p.short} subjects', '${p.name} subjects')]);
    }

    const notFound = _Reply(
        'I do not have that information yet. Update soon. Please ask the department '
        'or office, or try one of these:',
        _starterChips);

    if (scored.isEmpty) return courseOnly() ?? notFound;

    if (q.length == 1) {
      final word = q.first;
      final exact = scored
          .where((h) => h.doc.titleWords.length == 1 && h.doc.titleWords.contains(word))
          .toList();
      if (exact.length == 1) return _Reply(exact.first.doc.answer);
      final cands = scored.take(8).toList();
      if (cands.length >= 2) return _listReply('Here is what I have. Tap one:', cands);
      return _Reply(cands.first.doc.answer);
    }

    if (scored.first.score < 2) return courseOnly() ?? notFound;

    final top = scored.first;
    final second = scored.length > 1 ? scored[1].score : 0;
    if (top.score >= second + 2) return _Reply(top.doc.answer);

    final close = scored.where((h) => h.score >= top.score - 1).take(5).toList();
    return _listReply('I found a few matches. Tap the one you mean:', close);
  }

  // ------------------------------------------------------------ screen

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _input.clear();
    final r = _answer(t);
    setState(() {
      _msgs.add(_Msg(true, t));
      _msgs.add(_Msg(false, r.text, r.chips));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _bubble(_Msg m, bool isLast) {
    final user = m.fromUser;
    return Column(
      crossAxisAlignment: user ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: user ? KareColors.blue : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: user
                  ? null
                  : const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))],
            ),
            child: SelectableText(
              m.text,
              style: TextStyle(color: user ? Colors.white : Colors.black87, height: 1.4),
            ),
          ),
        ),
        if (!user && isLast && m.chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [
                for (final c in m.chips)
                  ActionChip(
                    label: Text(c.label),
                    onPressed: () => _send(c.query),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KareColors.blue,
        foregroundColor: Colors.white,
        title: const Text('KARE Help Bot'),
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              itemCount: _msgs.length,
              itemBuilder: (_, i) => _bubble(_msgs[i], i == _msgs.length - 1),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 6, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _send,
                          decoration: const InputDecoration(
                            hintText: 'Ask about fees, hostel, library…',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Send',
                        icon: const Icon(Icons.send),
                        color: KareColors.blue,
                        onPressed: () => _send(_input.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Answers come from the information stored in this app.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
