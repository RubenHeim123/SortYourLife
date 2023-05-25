import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';
import '../models/user.dart';
import 'databasehelper.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.username, required this.pwd, required this.offline});
  final String username;
  final String pwd; 
  final bool offline;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final global = Globals();

  @override
  void initState() {
    nameController.text = widget.username;
    passwordController.text = widget.pwd;
    super.initState();    
  }

  Future<bool> _getCredentials(String name, String passwd) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(await DatabaseHelper.instance.isAuthenticated(User(username:name, password:passwd, token: ''))){  
      await prefs.setString('username', name);
      await prefs.remove('tokenTime');
      await prefs.setBool('hasOfflineDatabase', true);
      return true;
    } else {
      await prefs.setBool('hasOfflineDatabase', false);
      return false;
    }
  }

  Future<bool> _getToken(String name, String passwd) async {
    final global = Globals();

    final response = await http.post(
      Uri.parse("${global.URL_PREFIX}api-token-auth/"),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'username': name,
        'password': passwd,
      }),
    );

    if (response.statusCode == 200) {
      String token = jsonDecode(response.body)['token'];
      // Use the obtained token to make authenticated requests to the API
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('username', name);
      await prefs.setInt('tokenTime', DateTime.now().millisecondsSinceEpoch);
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:Form(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Text(
                'Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                keyboardType: TextInputType.text,
                autocorrect: false,
                decoration: const InputDecoration(  
                  labelText: 'Benutzername',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Benutzername eingeben';
                  }
                  return null;
                },
                controller: nameController,
              ),
              const SizedBox(height: 20),
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Bitte Passwort eingeben';
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  bool offlineAuthenticated = await _getCredentials(nameController.text, passwordController.text);
                  if(widget.offline){  
                    passwordController.clear();
                    if (offlineAuthenticated){
                      nameController.clear();
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => MyHomePage(offline: widget.offline),
                      ));
                    } else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ihr Benutzername oder Passwort ist falsch')),
                      );
                    }
                  } else {
                    if (widget.username != '' && widget.username == nameController.text){
                      if(offlineAuthenticated){
                        await DatabaseHelper.instance.syncOfflineToOnline(nameController.text, passwordController.text);
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => MyHomePage(offline: widget.offline),
                        ));
                      }
                    } else {
                      bool authenticated = await _getToken(nameController.text, passwordController.text);
                      if (authenticated){
                        if(offlineAuthenticated){
                          await DatabaseHelper.instance.syncOfflineToOnline(nameController.text, passwordController.text);
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => MyHomePage(offline: widget.offline),
                          ));
                          nameController.clear();
                        }
                      } else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ihr Benutzername oder Passwort ist falsch')),
                        );
                      }
                      passwordController.clear();
                    }
                  }
                }, 
                child: const Text('Login'),
              )
            ]
          ) 
        ),
      )
    );
  }
}