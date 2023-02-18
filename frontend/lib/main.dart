import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main(){runApp(const MyApp());}

class MyApp extends StatelessWidget {
  const MyApp ({Key? key}): super (key:key);

  Future<http.Response> buttonPressed() async {
    http.Response returnedResult = await http.get(
      Uri.parse('http://192.168.0.18:8000/finance/hellodjango'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset-UTF-8'
      }
    );
    print(returnedResult.body);
    return returnedResult;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sort Your Life',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Sort Your Life'),
        ),
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: const Text('Welcome to Sort Your Life'),
              ),
              Padding(
                padding: const EdgeInsets.all(0.0),
                child: ElevatedButton(
                  onPressed: buttonPressed,
                  child: Text('Click!')
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}