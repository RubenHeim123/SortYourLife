import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutterfrontend/general/registration.dart';
import '../globals.dart';
import '../general/navigationdrawer.dart' as m;
import 'databasehelper.dart';
import '../models/user.dart';
import 'package:encrypt/encrypt.dart' as enc;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.offline});
  final bool offline;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final global = Globals();

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      body: FutureBuilder<List<User>>(
        future: DatabaseHelper.instance.getAllUser(),  // Future-Variable verwenden
        builder: (BuildContext context, AsyncSnapshot<List<User>> snapshot) {
          if(snapshot.hasData){
            return SingleChildScrollView(
              child: Column(
                children:[
                  Card(
                    child: ListTile(
                      title: const Text('Registriere neuen Nutzer'),
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const RegistrationPage(offlineDatabase: true,),
                        )).then((value) => setState((){}));
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text('Lösche Offline Datenbank'),
                      onTap: () async {
                        await DatabaseHelper.instance.deleteDatabase();
                        setState((){});
                      },
                    ),
                  ),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (BuildContext context, int index) {
                      return Slidable(
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (BuildContext context) async{
                              },
                              backgroundColor: Colors.green,
                              icon: Icons.edit,
                              label: 'Bearbeiten',
                            ),
                            SlidableAction(
                              onPressed: (BuildContext context){
                                setState((){
                                  DatabaseHelper.instance.deleteUser(snapshot.data![index].id!);
                                });
                              },
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: 'Löschen',
                            )
                          ]
                        ),  
                        child: Card(
                          child: ListTile(
                            title: Text(snapshot.data![index].username, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${snapshot.data![index].id}\n${snapshot.data![index].token}\n${snapshot.data![index].password}', style: const TextStyle(color: Colors.white)),
                          )
                        )
                      );
                    }
                  )
                ]
              )
            );
          } else {
            return const Text('Verstehe ich nicht');
          }
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
        },
        child: const Icon(Icons.add),
      ), 
    );
  }

  String encrypt(String pwd){
    final key = enc.Key.fromLength(32);
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));

    final encrypted = encrypter.encrypt(pwd, iv: iv);
    return encrypted.base64;
  }
}