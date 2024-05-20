import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book_response.dart'; // Use the BookResponse model
import 'BookDetailScreen.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookResponse>> getFavoriteBooks() {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => BookResponse.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList());
    } else {
      return Stream.empty(); // Handle no user logged in.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Favorites')),
      body: StreamBuilder<List<BookResponse>>(
        stream: getFavoriteBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error.toString()}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No favorites added."));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              BookResponse book = snapshot.data![index];
              print("BookResponse: $book"); // Debug statement
              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: book.imageUrl ?? '',
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                    width: 50,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  onTap: () {
                    print("Navigating to BookDetailScreen with biblioId: ${book.biblioId}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(biblioId: book.biblioId),
                      ),
                    );
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => removeFromFavorites(book.id!), // Use the document ID for deletion
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void removeFromFavorites(String docId) {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(docId)
          .delete()
          .catchError((error) {
        print("Error removing favorite: $error");
      });
    }
  }
}
