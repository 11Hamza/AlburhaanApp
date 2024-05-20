import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alburhaan/widget/signup_screen.dart';
import '../firebase/auth_service.dart';
import 'HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _loginWithEmailPassword() async {
    try {
      UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen())); // Navigate to HomeScreen
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              validator: (value) => (value != null && !value.contains('@')) ? 'Enter a valid email' : null,
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => (value != null && value.length < 6) ? 'Password must be at least 6 characters' : null,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginWithEmailPassword,
              child: Text('Login'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                User? user = await _authService.signInWithGoogle();
                if (user != null) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen())); // Navigate to HomeScreen
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in with Google')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Sign in with Google'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => SignupScreen()));
              },
              child: Text("Don't have an account? Sign up"),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
