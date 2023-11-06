import 'package:flutter/material.dart';

import 'general/start.dart';



void main(){runApp(const MyApp());}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  // @override
  // void initState() {
  //   super.initState(); 
  //   WidgetsBinding.instance.addObserver(this);
  // }

  // void dispose(){
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   super.didChangeAppLifecycleState(state);
    
  //   if (state == AppLifecycleState.paused) {
  //     await DatabaseHelper.instance.syncOnlineToOffline();
  //   } 
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sort Your Life',
      theme: ThemeData.dark(),
      home: const Start(),
    );
  }
} 