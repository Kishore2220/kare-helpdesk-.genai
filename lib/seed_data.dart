import 'package:cloud_firestore/cloud_firestore.dart';

/// Starter data for the app. An admin loads it once with the
/// "Load starter data" button on the Admin dashboard.

class SeedProgram {
  final String name;
  final int tuition; // per year, before scholarship (2026-27 KARE fee page)
  final int other; // per year, 0 = not listed
  final int years;
  final Map<int, String> subjects; // year -> subjects separated by |
  const SeedProgram(this.name, this.tuition, this.other, this.years, this.subjects);
}

const _common1 =
    'Calculus and Linear Algebra|Engineering Physics|Engineering Chemistry|Programming for Problem Solving|Engineering Graphics|Communicative English|Physics / Chemistry Lab|Programming Lab';

// Subjects are typical for each branch - check your own regulation.
const kSeedPrograms = <SeedProgram>[
  SeedProgram('B.Tech Computer Science & Engineering (CSE)', 195000, 12000, 4, {
    2: 'Data Structures|Discrete Mathematics|Digital Logic & Computer Organization|Object Oriented Programming|Database Management Systems|Probability & Statistics',
    3: 'Operating Systems|Computer Networks|Design & Analysis of Algorithms|Software Engineering|Theory of Computation|Compiler Design|Machine Learning',
    4: 'Cloud Computing|Cryptography & Network Security|Professional Elective|Open Elective|Project Work / Internship',
  }),
  SeedProgram('B.Tech Artificial Intelligence & Data Science (AI&DS)', 195000, 12000, 4, {
    2: 'Data Structures|Probability & Statistics|Database Management Systems|Python for Data Science|Discrete Mathematics|Object Oriented Programming',
    3: 'Machine Learning|Deep Learning|Big Data Analytics|Natural Language Processing|Data Visualization|Operating Systems',
    4: 'Computer Vision|Reinforcement Learning|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Information Technology (IT)', 195000, 12000, 4, {
    2: 'Data Structures|Database Management Systems|Computer Organization|Java Programming|Discrete Mathematics|Web Technologies',
    3: 'Operating Systems|Computer Networks|Software Engineering|Information Security|Mobile Application Development|Cloud Computing',
    4: 'Internet of Things|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Electronics & Communication (ECE)', 160000, 12000, 4, {
    2: 'Electronic Devices & Circuits|Signals and Systems|Digital Electronics|Network Analysis|Electromagnetic Fields|Analog Circuits',
    3: 'Digital Signal Processing|Communication Systems|Microprocessors & Microcontrollers|VLSI Design|Control Systems|Antenna & Wave Propagation',
    4: 'Embedded Systems|Wireless Communication|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Biotechnology', 160000, 12000, 4, {
    2: 'Biochemistry|Microbiology|Cell Biology|Genetics|Bioprocess Principles|Thermodynamics',
    3: 'Molecular Biology|Genetic Engineering|Immunology|Bioinformatics|Downstream Processing|Bioreactor Design',
    4: 'Animal / Plant Biotechnology|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Mechanical Engineering', 100000, 12000, 4, {
    2: 'Engineering Mechanics|Thermodynamics|Fluid Mechanics|Strength of Materials|Manufacturing Technology|Material Science',
    3: 'Heat and Mass Transfer|Design of Machine Elements|Dynamics of Machinery|CAD / CAM|Thermal Engineering|Metrology',
    4: 'Industrial Engineering|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Civil Engineering', 100000, 12000, 4, {
    2: 'Strength of Materials|Fluid Mechanics|Surveying|Building Materials & Construction|Structural Analysis|Concrete Technology',
    3: 'Geotechnical Engineering|Design of RC Structures|Transportation Engineering|Environmental Engineering|Water Resources Engineering|Estimation & Costing',
    4: 'Design of Steel Structures|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Electrical & Electronics (EEE)', 100000, 12000, 4, {
    2: 'Circuit Theory|Electrical Machines I|Electromagnetic Theory|Analog & Digital Electronics|Measurements & Instrumentation|Power Generation',
    3: 'Electrical Machines II|Power Systems Analysis|Control Systems|Power Electronics|Microcontrollers|Transmission & Distribution',
    4: 'Protection & Switchgear|Renewable Energy|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('B.Tech Aeronautical Engineering', 100000, 12000, 4, {
    2: 'Fluid Mechanics|Thermodynamics|Aircraft Structures|Aerodynamics I|Materials for Aerospace|Aircraft Systems',
    3: 'Propulsion|Flight Dynamics|Aerodynamics II|Control Engineering|Avionics|Aircraft Design',
    4: 'Aircraft Maintenance|Professional Elective|Open Elective|Project Work',
  }),
  SeedProgram('MBA', 150000, 0, 2, {
    1: 'Management Principles|Financial Accounting|Marketing Management|Business Statistics|Organizational Behaviour|Managerial Economics',
    2: 'Strategic Management|Operations Management|Human Resource Management|Specialisation Electives|Project Work',
  }),
  SeedProgram('MCA', 150000, 0, 2, {
    1: 'Data Structures|Database Systems|Operating Systems|Object Oriented Programming|Computer Networks|Discrete Mathematics',
    2: 'Software Engineering|Cloud Computing|Machine Learning|Elective|Project Work',
  }),
];

List<Map<String, dynamic>> buildSeedInfoItems() {
  final out = <Map<String, dynamic>>[];

  void add(String section, String title,
      {String? group, String? subtitle, String? details, String? icon, String? action}) {
    out.add({
      'section': section,
      'group_title': group,
      'title': title,
      'subtitle': subtitle,
      'details': details,
      'icon': icon,
      'action': action,
    });
  }

  // ---- Academic ----
  add('academic', 'Courses & Subjects',
      subtitle: 'Year-wise subjects for every course', icon: 'menu_book', action: 'screen:programs');
  add('academic', 'Examination',
      subtitle: 'Mid-sem, practicals and end-sem', icon: 'edit_note', action: 'screen:exams');
  add('academic', 'Fees', subtitle: 'Course-wise fees', icon: 'payments', action: 'screen:fees');
  add('academic', 'Academic Calendar', icon: 'event');
  add('academic', 'Regulations', icon: 'gavel');
  add('academic', 'Attendance', icon: 'fact_check');
  add('academic', 'Departments', icon: 'account_balance');
  add('academic', 'Faculty / Office Information', icon: 'badge');

  // ---- Hostel ----
  for (var i = 1; i <= 7; i++) {
    add('hostel', 'MH$i',
        group: "Men's Hostels (MH1 - MH7)", subtitle: "Men's hostel $i", icon: 'apartment');
  }
  for (var i = 1; i <= 5; i++) {
    add('hostel', 'L$i',
        group: 'Ladies Hostels (L1 - L5)', subtitle: 'Ladies hostel $i', icon: 'apartment');
  }
  add('hostel', 'Room Information', group: 'Hostel Help', icon: 'bed');
  add('hostel', 'Mess', group: 'Hostel Help', icon: 'restaurant');
  add('hostel', 'Laundry', group: 'Hostel Help', icon: 'laundry');
  add('hostel', 'Wi-Fi', group: 'Hostel Help', icon: 'wifi');
  add('hostel', 'Water', group: 'Hostel Help', icon: 'water');
  add('hostel', 'Report a Maintenance Problem',
      group: 'Hostel Help', subtitle: 'Water, electricity, repairs', icon: 'build', action: 'report:Hostel');
  add('hostel', 'Hostel Rules', group: 'Hostel Help', icon: 'rule');
  add('hostel', 'Warden / Help Desk', group: 'Hostel Help', icon: 'phone');

  // ---- Campus blocks ----
  for (final b in ['Block 5', 'Block 8', 'Block 9', 'Block 10', 'Block 11']) {
    add('blocks', b, icon: 'domain');
  }
  add('blocks', 'Computer Block', icon: 'computer');
  add('blocks', 'TIFAC CORE', icon: 'science');
  add('blocks', 'Central Library', icon: 'library', action: 'screen:library');

  // ---- Examination ----
  add('exams', 'Mid-Semester Practical', icon: 'science');
  add('exams', 'End-Semester Practical', icon: 'biotech');
  add('exams', 'End-Semester Exam', icon: 'edit_note');
  add('exams', 'Exam Registration', icon: 'how_to_reg');
  add('exams', 'Time Table', icon: 'calendar');
  add('exams', 'Results', icon: 'assessment');

  // ---- Library ----
  add('library', 'Library Timings', icon: 'schedule');
  add('library', 'Find a Project Report / Thesis', icon: 'search');
  add('library', 'Competitive Exam Preparation', icon: 'trophy');
  add('library', 'Book Search & Borrowing', icon: 'book');
  add('library', 'Digital Resources', icon: 'cloud');

  // ---- Medical ----
  add('medical', 'Kalasalingam Hospital',
      subtitle: 'Hospital facility is available for students',
      details:
          'Kalasalingam Hospital is available for KARE students.\n\nTimings, doctors and contact numbers: update soon.',
      icon: 'hospital');
  add('medical', 'Emergency', icon: 'emergency');
  add('medical', 'Ambulance', icon: 'ambulance');
  add('medical', 'Medical Leave / Certificates', icon: 'description');

  // ---- Transport ----
  for (final r in ['Madurai', 'Srivilliputtur', 'Rajapalayam', 'Sivakasi', 'Watrap']) {
    add('transport', r, group: 'Bus Routes', icon: 'bus');
  }
  add('transport', 'Bus Information', group: 'Bus Details', icon: 'info');
  add('transport', 'Boarding Points', group: 'Bus Details', icon: 'place');

  // ---- Events & clubs ----
  add('events', 'Upcoming Events', icon: 'event');
  add('events', 'Clubs', icon: 'groups');
  add('events', 'Sports', icon: 'sports');

  // ---- IT / Wi-Fi ----
  add('it', 'Report a Wi-Fi / IT Problem', icon: 'wifi_off', action: 'report:IT / Wi-Fi');
  add('it', 'Wi-Fi Login Help', icon: 'wifi');
  add('it', 'Computer Labs', icon: 'computer');
  add('it', 'IT Support Contact', icon: 'phone');

  // ---- Canteens ----
  const update = '\n\nTimings and menu prices: update soon.';
  add('canteens', 'Nalabagam Canteen',
      subtitle: 'All kinds of food, like in a hotel',
      details: 'Every kind of food you find in a hotel is available at Nalabagam Canteen.$update',
      icon: 'restaurant');
  add('canteens', 'Varshini Canteen',
      subtitle: 'All kinds of food, like in a hotel',
      details: 'Every kind of food you find in a hotel is available at Varshini Canteen.$update',
      icon: 'fastfood');
  add('canteens', 'Radha Krishnan Canteen',
      subtitle: 'Andhra food - Dum Biryani, Naan and more',
      details:
          'Andhra-style food such as Dum Biryani, Naan and more is available at Radha Krishnan Canteen.$update',
      icon: 'ramen');

  return out;
}

String _two(int n) => n.toString().padLeft(2, '0');
String _three(int n) => n.toString().padLeft(3, '0');

/// Writes courses, subjects and information pages. Safe to press twice
/// (same document ids are overwritten, nothing is duplicated).
Future<void> seedStarterData() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();

  for (var i = 0; i < kSeedPrograms.length; i++) {
    final p = kSeedPrograms[i];
    final subjects = <String, dynamic>{};
    if (p.name.startsWith('B.Tech')) subjects['1'] = _common1.split('|');
    p.subjects.forEach((year, s) => subjects['$year'] = s.split('|'));
    batch.set(db.collection('programs').doc('p${_two(i + 1)}'), {
      'name': p.name,
      'tuition': p.tuition,
      'other_fee': p.other,
      'years': p.years,
      'sort_order': i + 1,
      'subjects': subjects,
    });
  }

  final items = buildSeedInfoItems();
  for (var i = 0; i < items.length; i++) {
    batch.set(db.collection('info_items').doc('i${_three(i + 1)}'), {
      ...items[i],
      'sort_order': i + 1,
    });
  }

  await batch.commit();
}
