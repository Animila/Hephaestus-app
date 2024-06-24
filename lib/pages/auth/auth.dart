import 'dart:io';

import 'package:admin/pages/auth/verify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:form_validator/form_validator.dart';


class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  _AuthState createState() => _AuthState();
}


class _AuthState extends State<Auth> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final Widget logoSVG = SvgPicture.asset(
      'assets/logo.svg',
      semanticsLabel: 'Acme Logo',
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logoSVG,
            const SizedBox(height: 10),
            const Text(
              'ГЕФЕСТ Админ',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _errorMessage == null ? Colors.grey : Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _errorMessage == null ? Colors.blue : Colors.red),
                        ),
                        errorText: _errorMessage,
                      ),
                      validator: ValidationBuilder().email().build(),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: 204,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xffFFFFFF),
                          backgroundColor: const Color(0xff1E3A8A),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text('Вход'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _postWithHttpOverrides(
        Uri.parse('https://animila.ru/api/auth/login'),
        body: {'email': emailController.text},
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Verify(email: emailController.text,)), // Replace with your next page
        );
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'Почта не найдена';
        });
      } else {
        setState(() {
          _errorMessage = 'Неизвестная ошибка';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка из-за: $e';
      });
    }
  }

  Future<http.Response> _postWithHttpOverrides(Uri url, {Map<String, String>? body}) async {
    HttpOverrides.global = _MyHttpOverrides();
    return await http.post(url, body: body);
  }
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

