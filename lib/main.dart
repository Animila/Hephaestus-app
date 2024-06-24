import 'dart:convert';
import 'dart:io';

import 'package:admin/pages/auth/auth.dart';
import 'package:admin/pages/auth/verify.dart';
import 'package:admin/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static void navigateToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );
  }

  static void navigateToAuth(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Auth()),
    );
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    loadTokenFromStorage().then((token) {
      if (token != null) {
        _checkToken(token);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        title: 'Гефест Админ',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      return MaterialApp(
        title: 'Гефест Админ',
        debugShowCheckedModeBanner: false,
        home: _hasToken ? const Home() : const Auth(),
        routes: {
          '/auth': (context) => const Auth(),
          '/verify': (context) => Verify(),
          '/home': (context) => const Home()
        },
      );
    }
  }

  void _checkToken(String? token) async {
    AlertDialog(title: Text('345678765456'), content: Text('${token}'),);
    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Uri profileUrl = Uri.parse('https://animila.ru/api/user/profile');

    try {
      final response = await http.get(
        profileUrl,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $token',
        },
      );

      AlertDialog(title: Text('23456789098765'), content: Text('${response}'),);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String roleTitle = responseData['role']['title'];

        if (roleTitle == 'Администратор') {
          setState(() {
            _hasToken = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<String?> loadTokenFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}
