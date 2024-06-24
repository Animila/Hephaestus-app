import 'dart:io';
import 'dart:convert';
import 'package:admin/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Verify extends StatefulWidget {
  String? email;
  Verify({super.key, this.email});

  @override
  _VerifyState createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  final TextEditingController otpController = TextEditingController();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '6-ти значный код',
                      border: OutlineInputBorder(),
                      errorText: _errorMessage,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите OTP код';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
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
                      onPressed: _isLoading ? null : _verifyOTP,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : const Text('Подтвердить'),
                    ),
                  ),
                ])
              )
            )
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String email = widget.email!; // Замените на ваш email
    final String token = otpController.text;

    final Map<String, String> body = {
      'email': email,
      'token': token,
    };

    try {
      final response = await _postWithHttpOverrides(
        Uri.parse('https://animila.ru/api/auth/verify'),
        body: body,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 201) {
        // Успешная верификация, сохраняем токен
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String accessToken = responseData['access_token'];

        await saveTokenToStorage(accessToken);

        // После сохранения токена переходим на следующую страницу
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } else {
        // Неуспешная верификация
        setState(() {
          _errorMessage = 'Ошибка верификации';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка из-за: $e';
      });
    }
  }

  bool _validateInputs() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  Future<http.Response> _postWithHttpOverrides(Uri url, {required Map<String, String> body}) async {
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

Future<void> saveTokenToStorage(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}