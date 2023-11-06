import 'package:flutter/material.dart';
import 'package:flutterfrontend/general/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../finance/account.dart';
import '../finance/category.dart';
import '../finance/fix.dart';
import '../finance/overview.dart';
import '../finance/transaction.dart';
import 'help.dart';

class NavigationDrawer extends StatelessWidget{
  const NavigationDrawer({Key? key, required this.offline}) : super(key: key);
  final bool offline;

  Future<String?> _getUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  @override
  Widget build(BuildContext context){ 
    return Drawer(
      child: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              InkWell(
                onTap: (){
                  Navigator.pop(context);
                },
                child: SizedBox(
                  height: 200,
                  child: DrawerHeader(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 52,
                          backgroundImage:AssetImage(
                            "assets/images/dragon.jpg"
                          ),
                        ),
                        FutureBuilder<String?>(
                          future: _getUsername(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: const TextStyle(fontSize: 28, color: Colors.white),
                              );
                            } else {
                              return const Text(
                                'Loading...',
                                style: TextStyle(fontSize: 28, color: Colors.white),
                              );
                            }
                          },
                        ),
                      ],
                    )
                  )
                )
              ),
              ListTile(
                title: const Text('Home'),
                leading: const Icon(Icons.home),
                onTap: (){
                  Navigator.of(context).popUntil(ModalRoute.withName('/'));
                },
              ),
              ExpansionTile(
                title: const Text('Privat'),
                leading: const Icon(Icons.person),
                childrenPadding: const EdgeInsets.only(left:60),
                children: [
                  ListTile(
                    title: const Text('Kalender'),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder:(context) => HelpPage(offline: offline))
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('ToDo'),
                    onTap: (){
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Urlaub'),
                    onTap: (){
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Finanzen'),
                leading: const Icon(Icons.account_balance),
                childrenPadding: const EdgeInsets.only(left:60),
                children: [
                  ListTile(
                    title: const Text('Übersicht'),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder:(context) => Overview(offline: offline))
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Einnahmen'),
                    onTap: (){  
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => TransactionPage(category: 'Einnahmen', offline: offline)),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Ausgaben'),
                    onTap: (){
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => TransactionPage(category: 'Ausgaben', offline: offline)),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Konten'),
                    onTap: (){
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => AccountPage(offline: offline)),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Kategorien'),
                    onTap: (){
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => CategoryPage(value: 'Einnahmen', offline: offline)),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Fixkosten'),
                    onTap: (){
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => FixPage(offline: offline)),
                      );
                    },
                  ),
                  ExpansionTile(
                    title: const Text('Investitionen'),
                    childrenPadding: const EdgeInsets.only(left:60),
                    children: [
                      ListTile(
                        title: const Text('Aktien'),
                        onTap: (){
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Immobilien'),
                        onTap: (){
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Selbstständigkeit'),
                        onTap: (){
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Shopping'),
                leading: const Icon(Icons.shopping_cart),
                childrenPadding: const EdgeInsets.only(left:60),
                children: [
                  ListTile(
                    title: const Text('Wunschliste'),
                    onTap: (){
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Einkaufsliste'),
                    onTap: (){
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Geschenke'),
                    onTap: (){
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              ListTile(
                title: const Text('Einstellungen'),
                leading: const Icon(Icons.settings),
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder:(context) => SettingsPage(offline: offline))
                  );
                },
              ),
              ListTile(
                title: const Text('Logout'),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  // if(!offline){
                  //   await DatabaseHelper.instance.syncOnlineToOffline();
                  // }
                  await prefs.remove('auth_token');
                  await prefs.remove('username');
                  await prefs.setBool('hasOfflineDatabase', true);
                  await prefs.remove('tokenTime');
                  Navigator.of(context).popUntil(ModalRoute.withName('/'));
                },
              ),
            ]
          )
        ),
      ),
    );
  }
}
