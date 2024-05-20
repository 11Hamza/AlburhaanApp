import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

import 'FavouritesScreen.dart';
import 'ProfileScreen.dart';
import 'books_list_screen.dart'; // Your BooksListScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadIcsEvents();
  }

  Future<void> _loadIcsEvents() async {
    final icsUrl = 'https://calendar.google.com/calendar/ical/hamzaaebrahim%40gmail.com/private-a03d1f18ba4bde05381d240b290df359/basic.ics';
    final response = await http.get(Uri.parse(icsUrl));
    if (response.statusCode == 200) {
      final events = _parseICal(response.body);
      setState(() {
        _events = events;
      });
    } else {
      print('Failed to load ICS file');
    }
  }

  Map<DateTime, List<String>> _parseICal(String icsContent) {
    print('ICS Content: $icsContent'); // Debug statement
    final lines = icsContent.split('\n');
    final events = <DateTime, List<String>>{};
    DateTime? currentStartDate;
    String? currentSummary;

    for (final line in lines) {
      if (line.startsWith('DTSTART')) {
        currentStartDate = _parseICalDate(line);
      } else if (line.startsWith('SUMMARY')) {
        currentSummary = line.split(':')[1].trim();
      } else if (line.startsWith('END:VEVENT')) {
        if (currentStartDate != null && currentSummary != null) {
          final eventDate = DateTime(currentStartDate.year, currentStartDate.month, currentStartDate.day);
          if (events[eventDate] == null) {
            events[eventDate] = [];
          }
          events[eventDate]!.add(currentSummary);
        }
        currentStartDate = null;
        currentSummary = null;
      }
    }

    print('Parsed Events: $events'); // Debug statement
    return events;
  }

  DateTime _parseICalDate(String line) {
    final dateStr = line.split(':')[1].trim();
    if (dateStr.contains('T')) {
      // Handle date-time format (YYYYMMDDTHHMMSSZ)
      return DateTime.parse(dateStr.substring(0, 8));
    } else {
      // Handle date-only format (YYYYMMDD)
      return DateTime.parse(dateStr);
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          actions: [
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
          ],
        ),
        body: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              eventLoader: _getEventsForDay,
            ),
            const SizedBox(height: 8.0),
            ..._getEventsForDay(_selectedDay ?? _focusedDay)
                .map((event) => ListTile(title: Text(event)))
                .toList(),
          ],
        ),
      ),
      BooksListScreen(), // Your BooksListScreen
      FavoritesScreen(), // Your FavoritesScreen
    ];

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
