

    import 'package:flutter/material.dart';
    import 'package:firebase_auth/firebase_auth.dart';

import 'books_list_screen.dart';

    class SignupScreen extends StatelessWidget {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    @override
    Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(title: Text("Sign Up")),
    body: Padding(
    padding: EdgeInsets.all(16),
    child: SingleChildScrollView(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
    TextFormField(
    controller: _emailController,
    decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email),
    border: OutlineInputBorder(),
    ),
    keyboardType: TextInputType.emailAddress,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (value) {
    if (value == null || !value.contains('@')) return 'Enter a valid email';
    return null;
    },
    ),
    SizedBox(height: 20),
    TextFormField(
    controller: _passwordController,
    decoration: InputDecoration(
    labelText: 'Password',
    prefixIcon: Icon(Icons.lock),
    border: OutlineInputBorder(),
    ),
    obscureText: true,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (value) {
    if (value == null || value.length < 6) return 'Password must be at least 6 characters';
    return null;
    },
    ),
    SizedBox(height: 20),
    ElevatedButton(
    onPressed: () async {
    try {
    UserCredential user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
    );
    if (user != null) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BooksListScreen()));
    }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign up: ${e.toString()}')));
    }
    },
    child: Text('Sign Up'),
    style: ElevatedButton.styleFrom(
    foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text Color (Foreground color)
    ),
    ),
    ],
    ),
    ),
    ),
    );
    }
    }
