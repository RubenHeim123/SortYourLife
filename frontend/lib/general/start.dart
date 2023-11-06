import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutterfrontend/general/registration.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../globals.dart';
import 'home.dart';
import 'login.dart';
import 'package:http/http.dart' as http;


class Start extends StatefulWidget {
  const Start({Key? key}) : super(key: key);

  @override
  StartState createState() => StartState();
}

class StartState extends State<Start>{ 
  final global = Globals();
  bool _isServerAvailable = false;

  Future<List<String>> getToken() async{
    final prefs = await SharedPreferences.getInstance();
    final tokenTime = prefs.getInt('tokenTime');
    if (tokenTime == null){
      return ['', ''];
    } else if ((DateTime.now().millisecondsSinceEpoch-tokenTime) >= 604800000){
      await prefs.remove('auth_token');
      await prefs.remove('tokenTime');
      return ['', ''];
    } else{
      final username = prefs.getString('username');
      final token = prefs.getString('auth_token');
      if (username != null && token != null){
        final response = await http.post(
          Uri.parse("${global.URL_PREFIX}finance/users/checkToken/"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'username': username,
            'token': token,
          }),
        );
        if (response.statusCode == 200) {
          return [username, 'Beispiel'];
        } else {
          throw Exception('Fehler beim Erstellen des Nutzers ${response.statusCode}');
        }
      }
      return ['', ''];
    }
  }

  Future<bool> checkBackend() async {
    try {
      final response = await http.get(Uri.parse("${global.URL_PREFIX}finance/users/checkBackendStatus/"));
      _isServerAvailable = true;
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
          constraints: const BoxConstraints.expand(),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                "assets/images/kiHintergrund.jpeg"
              ), 
              fit: BoxFit.cover
            ) 
          ),
        child: Container(
          alignment: const Alignment(0, 0.8),
          child: FutureBuilder<bool>(
            future: _isServerAvailable ? null : checkBackend(),  // Future-Variable verwenden
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData && snapshot.data!) {
                return ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  buttonPadding: const EdgeInsets.all(10),
                  buttonMinWidth: screenWidth/2-30,   
                  buttonHeight: 100,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: () async{
                        List<String> token = await getToken();
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => LoginPage(username: token[0], pwd: token[1], offline: false),
                        ));
                        
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: Size(screenWidth/2-30,35),
                      ),
                      child: const Text('Login'),
                    ),
                    ElevatedButton(
                      onPressed: (){
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const RegistrationPage(offlineDatabase: false,),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: Size(screenWidth/2-30,35),
                      ),
                      child: const Text('Sign Up'),
                    ),
                  ]
                );
              } else {
                return ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  buttonPadding: const EdgeInsets.all(10),
                  buttonMinWidth: screenWidth/2-30,   
                  buttonHeight: 100,
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: (){
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const MyHomePage(offline: true),
                        ));                        
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: Size(screenWidth/2-30,35),
                      ),
                      child: const Text('Offline Modus'),
                    ),
                  ]
                );
              }
            }   
          )
        )
      )
    );
  }
}

class OfflineDialog extends StatelessWidget {
  const OfflineDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Offline Modus'),
          content: const Text('Der Server ist nicht erreichbar. Wollen Sie im Offline Modus fortfahren'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Nein'),
              child: const Text('Nein'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'Ja'),
              child: const Text('Ja'),
            ),
          ],
        ),
      ),
      child: const Text('Show Dialog'),
    );
  }
}