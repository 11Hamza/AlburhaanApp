import 'package:flutter/material.dart';
import 'package:alburhaan/models/BookDetail.dart';
import 'package:alburhaan/services/KohaApiService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'WebViewContainer.dart';

class BookDetailScreen extends StatefulWidget {
  final int biblioId;

  const BookDetailScreen({Key? key, required this.biblioId}) : super(key: key);

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<BookDetail> _bookDetailFuture;
  bool isFavorited = false;

  @override
  void initState() {
    super.initState();
    _bookDetailFuture = KohaApiService().fetchBookDetail(widget.biblioId);
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.biblioId.toString())
          .get();
      if (doc.exists) {
        setState(() {
          isFavorited = true;
        });
      }
    }
  }

  Future<void> addToFavorites(BookDetail book) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(book.biblioId.toString());
      await ref.set({
        'biblioId': book.biblioId,
        'title': book.title,
        'author': book.author,
        'imageUrl': book.imageUrl,
        // Add other necessary fields
      });
      setState(() {
        isFavorited = true;
      });
    } else {
      print("User not logged in");
    }
  }

  Future<void> _sendReservationEmail(BookDetail book, String userEmail) async {
    final smtpServer = SmtpServer(
      'mail.al-burhaan.org',
      port: 465,
      ssl: true,
      username: 'no-reply@al-burhaan.org',
      password: r'{n9C&*=$iAN)',
    );

    final message = Message()
      ..from = Address('no-reply@al-burhaan.org', 'Al-Burhaan No-Reply')
      ..recipients.add('hamzaaebrahim@gmail.com') // Replace with the recipient's email address
      ..subject = 'Book Reservation Request'
      ..text = 'User Email: $userEmail\n\n'
          'Book Details:\n'
          'Title: ${book.title}\n'
          'Author: ${book.author}\n'
          'ISBN: ${book.isbn}\n'
          'Publisher: ${book.publisher}\n'
          'Publication Year: ${book.publicationYear}\n'
          'Shelf Number: ${book.shelfNumber}\n'
          'Call Number: ${book.callNumber}\n'
          'Language: ${book.language}\n'
          'Physical Description: ${book.physicalDescription}\n'
          'Series: ${book.series}\n'
          'Notes: ${book.notes}\n';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
    }
  }

  void _showConfirmationDialog(BookDetail book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Reservation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to reserve this book?'),
                SizedBox(height: 10),
                Text('Title: ${book.title}'),
                Text('Author: ${book.author}'),
                Text('ISBN: ${book.isbn}'),
                // Add more book details here
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendReservationEmail(book, FirebaseAuth.instance.currentUser?.email ?? '');
                _showWaitForResponseDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showWaitForResponseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reservation Submitted'),
          content: Text('Please wait for a response via email.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Details')),
      body: FutureBuilder<BookDetail>(
        future: _bookDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (snapshot.data!.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 20.0),
                      child: Image.network(
                        snapshot.data!.imageUrl!,
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.image_not_supported, size: 200)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detailSection("Title", snapshot.data!.title),
                        detailSection("Author", snapshot.data!.author),
                        detailSection("ISBN", snapshot.data!.isbn),
                        detailSection("Publisher", snapshot.data!.publisher),
                        detailSection("Publication Year", snapshot.data!.publicationYear),
                        detailSection("Shelf Number", snapshot.data!.shelfNumber),
                        detailSection("Call Number", snapshot.data!.callNumber),
                        detailSection("Language", snapshot.data!.language),
                        detailSection("Physical Description", snapshot.data!.physicalDescription),
                        detailSection("Series", snapshot.data!.series),
                        detailSection("Notes", snapshot.data!.notes),
                        youtubeVideoSection(snapshot.data!.youtubeUrl),
                        if (snapshot.data!.ebookUrl != null)
                          ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WebViewContainer(url: snapshot.data!.ebookUrl!)
                                  )
                              ),
                              child: Text('Read eBook')
                          ),
                        SizedBox(height: 20), // Add space before the buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildFavoriteButton(snapshot.data!),
                            ),
                            SizedBox(width: 10), // Add space between buttons
                            Expanded(
                              child: _buildReserveButton(snapshot.data!),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildFavoriteButton(BookDetail book) {
    return ElevatedButton(
      onPressed: isFavorited ? null : () => addToFavorites(book),
      child: Text(isFavorited ? 'Added to Favorites' : 'Add to Favorites'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: isFavorited ? Colors.grey : Colors.brown, // Set text color
      ),
    );
  }

  Widget _buildReserveButton(BookDetail book) {
    return ElevatedButton(
      onPressed: () => _showConfirmationDialog(book),
      child: Text('Reserve Book'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: Colors.brown, // Set text color
      ),
    );
  }

  Widget detailSection(String title, String? content) {
    if (content == null || content.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          Expanded(flex: 3, child: Text(content, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget youtubeVideoSection(String? youtubeUrl) {
    if (youtubeUrl == null || youtubeUrl.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        height: 200,
        child: WebView(
          initialUrl: youtubeUrl,
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}
