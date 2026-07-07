import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AlumniEvent {
  final String id;
  final String title;
  final String date;
  final String location;
  final String description;
  bool isRsvped;

  AlumniEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    this.isRsvped = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'location': location,
    'description': description,
    'isRsvped': isRsvped,
  };

  factory AlumniEvent.fromJson(Map<String, dynamic> json) => AlumniEvent(
    id: json['id'],
    title: json['title'],
    date: json['date'],
    location: json['location'],
    description: json['description'],
    isRsvped: json['isRsvped'] ?? false,
  );
}

class AlumniRepository {
  static const String _eventsKey = 'local_alumni_events_v2';

  Future<List<AlumniEvent>> fetchUpcomingEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? eventsJson = prefs.getString(_eventsKey);

    if (eventsJson != null) {
      final List<dynamic> decodedList = jsonDecode(eventsJson);
      return decodedList.map((item) => AlumniEvent.fromJson(item)).toList();
    }

    final initialEvents = [
      AlumniEvent(
        id: 'evt_01',
        title: 'Tech Innovators Networking Mixer',
        date: 'August 15, 2026',
        location: 'Grand City Hotel',
        description: 'Join fellow graduates in the tech sector for an evening of networking, idea sharing, and opportunities with leading startups.',
      ),
      AlumniEvent(
        id: 'evt_02',
        title: 'Annual Alumni Gala Dinner',
        date: 'October 10, 2026',
        location: 'University Grand Hall',
        description: 'Celebrate the achievements of our outstanding alumni with a formal dinner and awards ceremony.',
      ),
    ];

    await prefs.setString(_eventsKey, jsonEncode(initialEvents.map((e) => e.toJson()).toList()));
    return initialEvents;
  }

  Future<void> toggleRsvp(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final events = await fetchUpcomingEvents();
    
    final index = events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      events[index].isRsvped = !events[index].isRsvped;
      await prefs.setString(_eventsKey, jsonEncode(events.map((e) => e.toJson()).toList()));
    }
  }
}