import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class BookConsultationScreen extends StatelessWidget {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final _emailController = TextEditingController(text: user?.email ?? ""); // Set the email to the user's email

    return Scaffold(
      appBar: AppBar(
        title: Text('Book a Consultation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              readOnly: true,
            ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: _requestController,
              decoration: InputDecoration(labelText: 'Request'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _sendEmail(
                  _emailController.text,
                  _subjectController.text,
                  _requestController.text,
                );
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail(String email, String subject, String request) async {
    final smtpServer = SmtpServer(
      'mail.al-burhaan.org',
      port: 465,
      ssl: true,
      username: 'no-reply@al-burhaan.org',
      password: r'{n9C&*=$iAN)',
    );

    final message = Message()
      ..from = Address('no-reply@al-burhaan.org', 'Al-Burhaan No-Reply')
      ..recipients.add('daruliftaa@al-burhaan.org') // Replace with the recipient's email address
      ..subject = subject
      ..text = 'Email: $email\n\nRequest: $request';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
    }
  }
}
