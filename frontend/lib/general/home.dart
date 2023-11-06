
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';
import '../general/navigationdrawer.dart' as m;
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.offline});
  final bool offline;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final global = Globals();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Sort Your Life'),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          var token = prefs.getString('auth_token');
          await http.delete(
            Uri.parse("${global.URL_PREFIX}finance/accountsdetails/-1"),
            headers: <String, String>{'Authorization': 'Token $token'},
            body: '{"account_name":"TesKonto","account_amount":"200.00"}'
          );
        },
        child: const Icon(Icons.add),
      ), 
    );
  }
}