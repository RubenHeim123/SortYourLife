import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../general/databasehelper.dart';
import '../general/navigationdrawer.dart' as m;
import '../globals.dart';
import '../models/account.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/update.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.offline});
  final bool offline;

  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  Client client = http.Client();
  List<Account> accounts = [];
  final accountListKey = GlobalKey<AccountPageState>();
  final global = Globals();

  @override
  void initState() {
    super.initState();
    _getAccountList();
  }

  _getAccountList() async {
    accounts = [];
    if(widget.offline){
      accounts = await DatabaseHelper.instance.getAllAccount();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;
      final response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/accountsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));
      for (var element in response) {
        accounts.add(Account.fromMap(element));
      }
    }    
    setState(() {});
  }

  deleteAccount(ac) async {
    if(widget.offline){
      await DatabaseHelper.instance.deleteAccount(ac);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ac), status: 'delete', tableName: 'accounts'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ac), status: 'delete', tableName: 'accounts'));
      }
      String token = prefs.getString('auth_token')!;
      await client.delete(
        Uri.parse("${global.URL_PREFIX}finance/accountsdetails/${ac.id}"),
        headers: <String, String>{'Authorization': 'Token $token'}
      );
    }
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: accountListKey,
      appBar: AppBar(
        title: const Text('Bankkonten'),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      body: RefreshIndicator(
        onRefresh: () async{
          _getAccountList();
        },
        child: ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (BuildContext context, int index) {
            return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (BuildContext context) async{
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => AccountDetailPage(account: accounts[index], offline: widget.offline)),
                      ).then((value){setState((){
                        _getAccountList();
                      });});
                    },
                    backgroundColor: Colors.green,
                    icon: Icons.edit,
                    label: 'Bearbeiten',
                  ),
                  SlidableAction(
                    onPressed: (BuildContext context){
                      deleteAccount(accounts[index]).whenComplete((){
                        setState((){
                          accounts.removeAt(index);
                        });
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
                  title: Text(accounts[index].accountName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(accounts[index].accountAmount, style: const TextStyle(color: Colors.white)),
                )
              )
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => NewAccountPage(offline: widget.offline))
          ).then((value){setState((){
            _getAccountList();
          });});
        },
        child: const Icon(Icons.add),
      ), 
    );
  }
}

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.account, required this.offline});
  final Account account;
  final bool offline;

  @override
  AccountDetailPageState createState() => AccountDetailPageState();
}

class AccountDetailPageState extends State<AccountDetailPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final global = Globals();
  final amountController = TextEditingController();
  final nameController = TextEditingController();
  List<String> list = <String>['Einnahmen', 'Ausgaben'];
  late String selectedCategory = list.first;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.account.accountName;
    amountController.text = widget.account.accountAmount;
  }

  changeAccount(ac) async {
    if(widget.offline){
      await DatabaseHelper.instance.updateAccount(ac);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(Account(accountName: widget.account.accountName, accountAmount: widget.account.accountAmount)), status: 'delete', tableName: 'accounts'));
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ac), status: 'create', tableName: 'accounts'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(Account(accountName: widget.account.accountName, accountAmount: widget.account.accountAmount)), status: 'delete', tableName: 'accounts'));
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ac), status: 'create', tableName: 'accounts'));
      }
      String token = prefs.getString('auth_token')!;
      await client.put(
        Uri.parse("${global.URL_PREFIX}finance/accountsdetails/${ac.id}"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: ac.toJson()
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Kategorie'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Kategorie Name',
                  ),
                  controller: nameController,
                ),
                TextFormField(
                  validator: (value){
                    if (value == null || value.isEmpty){
                      return 'Bitte gib eine Zahl ein';
                    } else if (value.contains(',')){
                      return 'Achte bitte auf das richtige Format';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Betrag',
                    hintText: 'XXXX.XX'
                  ),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()){
                      var am = double.parse(amountController.text);
                      var ac = Account(
                        accountName: nameController.text,
                        accountAmount: am.toStringAsFixed(2),
                        id: widget.account.id,
                      );
                      await changeAccount(ac);
                      _formKey.currentState!.reset();
                      Navigator.pop(context);
                    }
                  }, 
                  child: const Text('Submit'),
                )
              ],        
            ), 
          ),
        )
      )
    );
  }
}

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key, required this.offline});
  final bool offline;

  @override
  NewAccountPageState createState() => NewAccountPageState();
}

class NewAccountPageState extends State<NewAccountPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final amountController = TextEditingController();
  final nameController = TextEditingController();
  List<Account> accounts = [];
  List<String> list = <String>['Einnahmen', 'Ausgaben'];
  late String selectedCategory = list.first;
  final global = Globals();


  @override
  void initState() {
    super.initState();    
  }
 
  Future<bool> _createAccount(Account ac)async {
    if(widget.offline){
      await DatabaseHelper.instance.createAccount(ac);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ac), status: 'create', tableName: 'accounts'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ac), status: 'create', tableName: 'accounts'));
      }
      String token = prefs.getString('auth_token')!;
      final response = await http.post(
        Uri.parse("${global.URL_PREFIX}finance/accountsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: ac.toJson()
      );
      if(response.statusCode == 201){
        return true;
      }

    }
    setState(() {});
    return false;
  }
  
  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neues Konto '),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Konto Name',
                  ),
                  controller: nameController,
                ),
                TextFormField(
                  validator: (value){
                    if (value == null || value.isEmpty){
                      return 'Bitte gib eine Zahl ein';
                    } else if (value.contains(',')){
                      return 'Achte bitte auf das richtige Format';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Betrag',
                    hintText: 'XXXX.XX'
                  ),
                  controller: amountController,
                  keyboardType: TextInputType.number,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()){
                      var am = double.parse(amountController.text);
                      var ac = Account(
                        accountName: nameController.text,
                        accountAmount: am.toStringAsFixed(2),
                      );
                      final success = await _createAccount(ac);
                      nameController.clear();
                      amountController.clear();
                      _formKey.currentState!.reset();
                      if(success){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${ac.accountName} wurde angelegt')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${ac.accountName} wurde nicht angelegt')),
                        );
                      }
                    }
                  }, 
                  child: const Text('Submit'),
                )
              ],        
            ), 
          )
        )
      )
    );
  }
}