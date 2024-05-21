import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class GetFatwaScreen extends StatelessWidget {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final _emailController = TextEditingController(text: user?.email ?? ""); // Set the email to the user's email

    return Scaffold(
      appBar: AppBar(
        title: Text('Get a Fatwa'),
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
              controller: _questionController,
              decoration: InputDecoration(labelText: 'Question'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _sendEmail(
                  _emailController.text,
                  _subjectController.text,
                  _questionController.text,
                );
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmail(String email, String subject, String question) async {
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
      ..text = 'Email: $email\n\nQuestion: $question';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
    }
  }
}
