import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../globals.dart';
import '../general/navigationdrawer.dart' as m;
import '../models/update.dart';
import 'databasehelper.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key, required this.offline});
  final bool offline;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
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
      body: FutureBuilder<List<Update>>(
        future: DatabaseHelper.instance.getAllUpdatesFromAllUsers(),  // Future-Variable verwenden
        builder: (BuildContext context, AsyncSnapshot<List<Update>> snapshot) {
          if(snapshot.hasData){
            return SingleChildScrollView(
              child: Column(
                children:[
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
                                  DatabaseHelper.instance.deleteUpdate(snapshot.data![index].id!);
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
                            title: Text(snapshot.data![index].tableName, style: const TextStyle(color: Colors.white)),
                            subtitle: Text('${snapshot.data![index].id}\n${snapshot.data![index].status}\n${snapshot.data![index].data}', style: const TextStyle(color: Colors.white)),
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
    );
  }
}