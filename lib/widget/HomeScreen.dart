import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'IftaScreen.dart';
import 'ProfileScreen.dart';
import 'books_list_screen.dart';

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
    final icsUrl = 'https://outlook.office365.com/owa/calendar/dc6f54dbdc994f2f94e47e9c472b31b5@al-burhaan.org/2ef0eff4dbc440028b69af8315ff652e17792049010119840720/calendar.ics';
    final response = await http.get(Uri.parse(icsUrl));
    if (response.statusCode == 200) {
      final events = _parseICal(response.body);
      setState(() {
        _events = events;
        print('Loaded events: $_events');
      });
    } else {
      print('Failed to load ICS file');
    }
  }

  Map<DateTime, List<String>> _parseICal(String icsContent) {
    final lines = icsContent.split('\n');
    final events = <DateTime, List<String>>{};
    DateTime? currentStartDate;
    String? currentSummary;
    String? currentRRule;

    for (final line in lines) {
      if (line.startsWith('DTSTART')) {
        currentStartDate = _parseICalDate(line);
        print('Parsed DTSTART: $currentStartDate');
      } else if (line.startsWith('SUMMARY')) {
        currentSummary = line.split(':')[1].trim();
        print('Parsed SUMMARY: $currentSummary');
      } else if (line.startsWith('RRULE')) {
        currentRRule = line.split(':')[1].trim();
        print('Parsed RRULE: $currentRRule');
      } else if (line.startsWith('END:VEVENT')) {
        if (currentStartDate != null && currentSummary != null) {
          if (currentRRule != null) {
            _addRecurringEvents(events, currentStartDate, currentSummary, currentRRule);
          } else {
            final eventDate = DateTime(currentStartDate.year, currentStartDate.month, currentStartDate.day);
            if (!events.containsKey(eventDate)) {
              events[eventDate] = [];
            }
            events[eventDate]!.add(currentSummary);
            print('Added event on $eventDate: $currentSummary');
          }
        }
        currentStartDate = null;
        currentSummary = null;
        currentRRule = null;
      }
    }

    print('Parsed Events: $events');
    return events;
  }

  DateTime _parseICalDate(String line) {
    final dateStr = line.split(':')[1].trim();
    DateTime parsedDate;
    if (dateStr.contains('T')) {
      parsedDate = DateTime.parse(dateStr.substring(0, 8)); // Parse only the date part
    } else {
      parsedDate = DateTime.parse(dateStr.substring(0, 8)); // Parse only the date part
    }
    print('Parsed Date: $parsedDate');
    return parsedDate;
  }

  void _addRecurringEvents(Map<DateTime, List<String>> events, DateTime startDate, String summary, String rruleString) {
    final rruleParts = rruleString.split(';');
    String? freq;
    int? interval;
    List<int>? byDay;

    for (final part in rruleParts) {
      final keyVal = part.split('=');
      if (keyVal.length == 2) {
        final key = keyVal[0];
        final value = keyVal[1];

        if (key == 'FREQ') {
          freq = value;
        } else if (key == 'INTERVAL') {
          interval = int.tryParse(value);
        } else if (key == 'BYDAY') {
          byDay = value.split(',').map((day) => _dayStringToInt(day)).toList();
        }
      }
    }

    if (freq != null) {
      _generateRecurringEvents(events, startDate, summary, freq, interval, byDay);
    }
  }

  int _dayStringToInt(String day) {
    switch (day) {
      case 'MO':
        return DateTime.monday;
      case 'TU':
        return DateTime.tuesday;
      case 'WE':
        return DateTime.wednesday;
      case 'TH':
        return DateTime.thursday;
      case 'FR':
        return DateTime.friday;
      case 'SA':
        return DateTime.saturday;
      case 'SU':
        return DateTime.sunday;
      default:
        return DateTime.monday; // Default to Monday
    }
  }

  void _generateRecurringEvents(Map<DateTime, List<String>> events, DateTime startDate, String summary, String freq, int? interval, List<int>? byDay) {
    final endDate = DateTime.now().add(Duration(days: 365)); // Generate events for one year

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate)) {
      if (byDay != null) {
        for (final day in byDay) {
          DateTime eventDate = _nextWeekday(currentDate, day);
          if (!eventDate.isBefore(startDate) && eventDate.isBefore(endDate)) {
            _addEvent(events, eventDate, summary);
          }
        }
      } else {
        _addEvent(events, currentDate, summary);
      }

      if (freq == 'WEEKLY') {
        currentDate = currentDate.add(Duration(days: 7 * (interval ?? 1)));
      } else if (freq == 'DAILY') {
        currentDate = currentDate.add(Duration(days: (interval ?? 1)));
      } else {
        break;
      }
    }
  }

  DateTime _nextWeekday(DateTime from, int weekday) {
    int daysToAdd = (weekday - from.weekday) % 7;
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    return from.add(Duration(days: daysToAdd));
  }

  void _addEvent(Map<DateTime, List<String>> events, DateTime date, String summary) {
    final eventDate = DateTime(date.year, date.month, date.day);
    if (!events.containsKey(eventDate)) {
      events[eventDate] = [];
    }
    events[eventDate]!.add(summary);
    print('Added recurring event on $eventDate: $summary');
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final eventSummaries = _events[DateTime(day.year, day.month, day.day)] ?? [];
    final eventDetails = eventSummaries.map((summary) {
      return {
        'Event': summary,
        'Time': 'All Day', // Default time, can be modified to actual time if available
      };
    }).toList();
    print('Events for $day: $eventDetails');
    return eventDetails;
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
            Container(
              margin: EdgeInsets.all(16.0),
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TableCalendar(
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
                eventLoader: (day) => _getEventsForDay(day).map((e) => e['Event']).toList(),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.brown,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.brown,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  formatButtonTextStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16.0),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.brown),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListView(
                  children: _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                    return ListTile(
                      title: Text('Event: ${event['Event']}'),
                      subtitle: Text('Time: ${event['Time']}'),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      BooksListScreen(), // Your BooksListScreen
      IftaScreen(), // Your IftaScreen
    ];

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Ifta'), // Updated item
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown[500],
        onTap: _onItemTapped,
      ),
    );
  }
}
