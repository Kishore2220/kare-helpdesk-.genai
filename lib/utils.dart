import 'package:flutter/material.dart';

/// True when the logged-in user is an admin (set by the home screen).
bool kIsAdmin = false;

String inr(int n) {
  final s = n.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

String feeText(Map<String, dynamic> p) {
  final t = (p['tuition'] as num).toInt();
  final o = (p['other_fee'] as num).toInt();
  final y = (p['years'] as num).toInt();
  final b = StringBuffer()
    ..writeln('Annual tuition fee: ${inr(t)}')
    ..writeln(o > 0
        ? 'Other fees (soft skills, library, exams): ${inr(o)}'
        : 'Other fees: ask the Accounts Office')
    ..writeln('Total per year: ${inr(t + o)}')
    ..writeln('Approx. for $y years: ${inr((t + o) * y)}')
    ..writeln()
    ..write('2026-27, resident Indian students, before scholarship. '
        'Hostel and mess fees are extra. Confirm with the Accounts Office.');
  return b.toString();
}

const _icons = <String, IconData>{
  'menu_book': Icons.menu_book_outlined,
  'edit_note': Icons.edit_note_outlined,
  'payments': Icons.payments_outlined,
  'event': Icons.event_outlined,
  'gavel': Icons.gavel_outlined,
  'fact_check': Icons.fact_check_outlined,
  'account_balance': Icons.account_balance_outlined,
  'badge': Icons.badge_outlined,
  'apartment': Icons.apartment_outlined,
  'bed': Icons.bed_outlined,
  'restaurant': Icons.restaurant_outlined,
  'laundry': Icons.local_laundry_service_outlined,
  'wifi': Icons.wifi,
  'wifi_off': Icons.wifi_off_outlined,
  'water': Icons.water_drop_outlined,
  'build': Icons.build_outlined,
  'rule': Icons.rule_outlined,
  'phone': Icons.phone_outlined,
  'domain': Icons.domain_outlined,
  'computer': Icons.computer_outlined,
  'science': Icons.science_outlined,
  'library': Icons.local_library_outlined,
  'biotech': Icons.biotech_outlined,
  'how_to_reg': Icons.how_to_reg_outlined,
  'calendar': Icons.calendar_month_outlined,
  'assessment': Icons.assessment_outlined,
  'schedule': Icons.schedule_outlined,
  'search': Icons.search_outlined,
  'trophy': Icons.emoji_events_outlined,
  'book': Icons.menu_book_outlined,
  'cloud': Icons.cloud_outlined,
  'hospital': Icons.local_hospital_outlined,
  'emergency': Icons.emergency_outlined,
  'ambulance': Icons.airport_shuttle_outlined,
  'description': Icons.description_outlined,
  'bus': Icons.directions_bus_outlined,
  'place': Icons.place_outlined,
  'info': Icons.info_outline,
  'groups': Icons.groups_outlined,
  'sports': Icons.sports_soccer_outlined,
  'fastfood': Icons.fastfood_outlined,
  'ramen': Icons.ramen_dining_outlined,
};

IconData iconFor(String? name) => _icons[name] ?? Icons.info_outline;
