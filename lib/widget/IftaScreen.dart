import 'package:flutter/material.dart';
import 'get_fatwa_screen.dart';
import 'book_consultation_screen.dart';

class IftaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ifta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text('Get a Fatwa'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => GetFatwaScreen()),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Book a Consultation'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => BookConsultationScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
