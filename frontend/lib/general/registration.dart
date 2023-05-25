import 'dart:convert';

import 'package:flutter/material.dart';

import '../globals.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../models/user.dart';
import 'databasehelper.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key, required this.offlineDatabase}) : super(key: key);
  final bool offlineDatabase;

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  Client client = http.Client();
  final global = Globals();

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 4) {
      return 'Username must be at least 4 characters long';
    }
    return null;
  }

  Future<String> createOfflineUser(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse("${global.URL_PREFIX}api-token-auth/"),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      var users = await DatabaseHelper.instance.getAllUser();
      String token = jsonDecode(response.body)['token'];
      if(users.isEmpty){
        await DatabaseHelper.instance.createUser(User(username: username, password: encrypt(password), token: token));
        return 'Registrierung erfolgreich';
      }
      for (var user in users){
        if(user.username != username){
          await DatabaseHelper.instance.createUser(User(username: username, password: encrypt(password), token: token));
          return 'Registrierung erfolgreich';
        }
      }
      return 'Nutzer bereits vorhanden';
    } else {
      return 'Fehler beim Erstellen des Nutzers';
    }
  }

  String encrypt(String pwd){
    final key = enc.Key.fromLength(32);
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));

    final encrypted = encrypter.encrypt(pwd, iv: iv);
    return encrypted.base64;
  }

  Future<String> createUser(String username, String password, String email) async {
    final response = await client.post(
      Uri.parse("${global.URL_PREFIX}finance/users/create/"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
        'email': email,
      }),
    );
    if (response.statusCode == 201) {
      return 'Registrierung erfolgreich';
    } else {
      return 'Fehler beim Erstellen des Nutzers';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.offlineDatabase ? const Text('Registriere die Offline Datenbank mit denselben Anmeldedaten wie deinen Account. Bitte beachte dass jedes weitere Konto Speicherplatz benötigt.') : const Text(''),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: _validateUsername,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: _validatePassword,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      String text = '';
                      // Save the user's credentials in the database or elsewhere
                      if(widget.offlineDatabase){
                        text = await createOfflineUser(_usernameController.text,_passwordController.text,'');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(text))
                        );
                        Navigator.of(context).popUntil(ModalRoute.withName('/'));
                      } else {
                        text = await createUser(_usernameController.text,_passwordController.text,'');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(text))
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
