import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../general/databasehelper.dart';
import '../general/navigationdrawer.dart' as m;
import '../globals.dart';
import '../models/account.dart';
import '../models/incomecategory.dart';
import '../models/outgoingcategory.dart';
import '../models/transaction.dart';
import '../models/update.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key, required this.category, required this.offline});
  final String category;
  final bool offline;

  @override
  TransactionPageState createState() => TransactionPageState();
}

class TransactionPageState extends State<TransactionPage> {
  Client client = http.Client();
  List<Transaction> income = [];
  List<Transaction> outgoing = [];
  final transactionListKey = GlobalKey<TransactionPageState>();
  DateFormat dateFormat = DateFormat("dd.MM.yyyy");
  final global = Globals();

  @override
  void initState() {
    _getTransactionList();
    super.initState();
  }

  _getTransactionList() async {
    income = [];
    outgoing = [];
    if(widget.offline) {
      var trans = await DatabaseHelper.instance.getAllTransaction();
      for(var element in trans){
        if(element.transactionkind == 'Einnahme'){
          income.add(element);
        } else if (element.transactionkind == 'Ausgabe'){
          outgoing.add(element);
        }
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/transactionsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'},
      )).bodyBytes));

      for (var element in response) {
        var transaction = Transaction.fromMap(element);
        if (transaction.transactionkind =='Einnahme'){
          income.add(transaction);
        }else{
          outgoing.add(transaction);
        }
      }
      income.sort((a,b) => b.date.compareTo(a.date));
      outgoing.sort((a,b) => b.date.compareTo(a.date));
    }
    setState(() {});
  }

  deleteTransaction(tr) async {
    if(widget.offline) {
      await DatabaseHelper.instance.deleteTransaction(tr);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(tr), status: 'delete', tableName: 'transactions'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(tr), status: 'delete', tableName: 'transactions'));
      }
      String token = prefs.getString('auth_token')!;
      await client.delete(
        Uri.parse("${global.URL_PREFIX}finance/transactionsdetails/${tr.id}"),
        headers: <String, String>{'Authorization': 'Token $token'}
      );
    }
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: transactionListKey,
      appBar: AppBar(
        title: Text(widget.category),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      body: RefreshIndicator(
        onRefresh: () async{
          _getTransactionList();
        },
        child: widget.category == 'Einnahmen'?
        ListView.builder(
          itemCount: income.length,
          itemBuilder: (BuildContext context, int index) {
            return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (BuildContext context) async{
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => TransactionDetailPage(transaction: income[index], transactionTyp: 'Einnahmen',offline: widget.offline)),
                      );
                      setState((){_getTransactionList();});
                    },
                    backgroundColor: Colors.green,
                    icon: Icons.edit,
                    label: 'Bearbeiten',
                  ),
                  SlidableAction(
                    onPressed: (BuildContext context){
                      deleteTransaction(income[index]).whenComplete((){
                        setState((){
                          income.removeAt(index);
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
                  title: Text('${dateFormat.format(income[index].date)} ${income[index].category}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(income[index].amount.toString(), style: const TextStyle(color: Colors.white)),
                )
              ),
            );
          },
        )
        :ListView.builder(
          itemCount: outgoing.length,
          itemBuilder: (BuildContext context, int index) {
            return Slidable(
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                children: [
                  SlidableAction(
                    onPressed: (BuildContext context) async{
                      await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => TransactionDetailPage(transaction: outgoing[index], transactionTyp: 'Ausgaben',offline: widget.offline)),
                      );
                      setState((){_getTransactionList();});
                    },
                    backgroundColor: Colors.green,
                    icon: Icons.edit,
                    label: 'Bearbeiten',
                  ),
                  SlidableAction(
                    onPressed: (BuildContext context){
                      deleteTransaction(outgoing[index]).whenComplete((){
                        setState((){
                          outgoing.removeAt(index);
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
                  title: Text('${dateFormat.format(outgoing[index].date)} ${outgoing[index].category}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(outgoing[index].amount.toString(), style: const TextStyle(color: Colors.white)),
                )
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => NewTransactionPage(transaction: widget.category, offline: widget.offline)),
          ).then((value){setState(() {
            _getTransactionList();
          });});
        },
        child: const Icon(Icons.add),
      ), 
    );
  }
}

class TransactionDetailPage extends StatefulWidget {
  const TransactionDetailPage({super.key, required this.transactionTyp, required this.transaction, required this.offline});
  final String transactionTyp;
  final Transaction transaction;
  final bool offline;

  @override
  TransactionDetailPageState createState() => TransactionDetailPageState();
}

class TransactionDetailPageState extends State<TransactionDetailPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  List<OutgoingCategory> outgoingCategory = [];
  List<IncomeCategory> incomeCategory = [];
  List<Account> accounts = [];
  String selectedCategory = '';
  String selectedAccount = '';
  final global = Globals();

  @override
  void initState() {
    if(widget.transactionTyp == 'Einnahmen'){
      _getIncomeCategoryList();
    }else{
      _getOutgoingCategoryList();
    }
    _getAccountList();
    amountController.text = widget.transaction.amount.toString();
    dateController.text = _dateFormat.format(widget.transaction.date);
    descriptionController.text = widget.transaction.description;
    selectedCategory = widget.transaction.category;
    selectedAccount = widget.transaction.account;
    super.initState();    
  }

  _getAccountList() async {
    accounts = [];
    if(widget.offline) {
      accounts = await DatabaseHelper.instance.getAllAccount();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/accountsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));

      for (var element in response) {
        accounts.add(Account.fromMap(element));
      }
    }
    if(selectedAccount == '' && accounts.isNotEmpty){
      selectedAccount = accounts[0].accountName;
    }
    setState(() {});
  }

  _getOutgoingCategoryList() async {
    outgoingCategory = [];
    if(widget.offline) {
      outgoingCategory = await DatabaseHelper.instance.getAllOutgoingCategory();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/outgoingcategorysdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));

      for (var element in response) {
        outgoingCategory.add(OutgoingCategory.fromMap(element));
      }
    }
    if(selectedCategory == '' && outgoingCategory.isNotEmpty){
    selectedCategory = outgoingCategory[0].outgoingCategoryName; 
    } 
    setState(() {});
  }

  _getIncomeCategoryList() async {
    incomeCategory = [];
    if(widget.offline) {
      incomeCategory = await DatabaseHelper.instance.getAllIncomeCategory();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/incomecategorysdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));

      for (var element in response) {
        incomeCategory.add(IncomeCategory.fromMap(element));
      }
    }
    if(selectedCategory == '' && incomeCategory.isNotEmpty){
      selectedCategory = incomeCategory[0].incomeCategoryName;
    }
    setState(() {});
  }
  
  changeTransaction(tr) async {
    if(widget.offline) {
      await DatabaseHelper.instance.updateTransaction(tr);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(Transaction(account: widget.transaction.account, category: widget.transaction.category, description: widget.transaction.description, date: widget.transaction.date, transactionkind: widget.transactionTyp == 'Einnahmen' ? 'Einnahme' : 'Ausgabe', amount: widget.transaction.amount)), status: 'delete', tableName: 'transactions'));
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(tr), status: 'create', tableName: 'transactions'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(Transaction(account: widget.transaction.account, category: widget.transaction.category, description: widget.transaction.description, date: widget.transaction.date, transactionkind: widget.transactionTyp == 'Einnahmen' ? 'Einnahme' : 'Ausgabe', amount: widget.transaction.amount)), status: 'delete', tableName: 'transactions'));
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(tr), status: 'create', tableName: 'transactions'));
      }
      String token = prefs.getString('auth_token')!;
      await client.put(
        Uri.parse("${global.URL_PREFIX}finance/transactionsdetails/${tr.id}"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: tr.toJson()
      );
    }
  }
  
  @override
  void dispose() {
    dateController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Neue ${widget.transactionTyp}'),
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
                  validator: (value){
                    if (value == null || value.isEmpty){
                      return 'Bitte gib eine gültiges Datum ein';
                    } else if(!value.contains(RegExp(r'^\s*(3[01]|[12][0-9]|0?[1-9])\.(1[012]|0?[1-9])\.((?:19|20)\d{2})\s*$'))){
                      return 'Bitte gib das Datum im gültigen Format ein: dd.MM.yyyy';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Datum',
                    hintText: 'dd.MM.yyyy'
                  ),
                  controller: dateController,
                  keyboardType: TextInputType.number,
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
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                  ),
                  controller: descriptionController,
                ),
                DropdownButton(
                  value: selectedCategory,
                  items: widget.transactionTyp == 'Einnahmen'?
                    incomeCategory.map((IncomeCategory ic){
                      return DropdownMenuItem(
                        value: ic.incomeCategoryName,
                        child: Text(ic.incomeCategoryName)
                      );
                    }).toList()
                    : outgoingCategory.map((OutgoingCategory oc){ 
                    return DropdownMenuItem(
                      value: oc.outgoingCategoryName.toString(),
                      child: Text(oc.outgoingCategoryName),
                    );
                  }).toList(), 
                  onChanged: (String? newValue){
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
                DropdownButton(
                  value: selectedAccount,
                  items: accounts.map((Account acc){
                      return DropdownMenuItem(
                        value: acc.accountName,
                        child: Text(acc.accountName)
                      );
                    }).toList(), 
                  onChanged: (String? newValue){  
                    setState(() {
                      selectedAccount = newValue!;
                    });
                  }
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()){
                      var am = double.parse(amountController.text);
                      var tr = Transaction(
                        date: _dateFormat.parse(dateController.text), 
                        account: selectedAccount, 
                        amount: double.parse(am.toStringAsFixed(2)), 
                        category: selectedCategory, 
                        description: descriptionController.text, 
                        transactionkind: widget.transactionTyp == 'Einnahmen' ? 'Einnahme' : 'Ausgabe',
                        id: widget.transaction.id,
                      );
                      await changeTransaction(tr);
                      _formKey.currentState!.reset();
                      Navigator.pop(context);
                    }
                  }, 
                  child: const Text('Submit'),
                )
              ],        
            ), 
          ),
        ),
      ),
    );
  }
}

class NewTransactionPage extends StatefulWidget {
  const NewTransactionPage({super.key, required this.transaction, required this.offline});
  final String transaction;
  final bool offline;

  @override
  NewTransactionPageState createState() => NewTransactionPageState();
}

class NewTransactionPageState extends State<NewTransactionPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final amountController = TextEditingController();
  final dateController = TextEditingController();
  final descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  List<OutgoingCategory> outgoingCategory = [];
  List<IncomeCategory> incomeCategory = [];
  List<Account> accounts = [];
  String selectedCategory = '';
  String selectedAccount = '';
  final global = Globals();

  @override
  void initState() {
    if(widget.transaction == 'Einnahmen'){
      _getIncomeCategoryList();
    }else{
      _getOutgoingCategoryList();
    }
    _getAccountList();
    super.initState();    
  }

  _getAccountList() async {
    accounts = [];
    if(widget.offline) {
      accounts = await DatabaseHelper.instance.getAllAccount();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/accountsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));

      for (var element in response) {
        accounts.add(Account.fromMap(element));
      }
    }
    if(accounts.isNotEmpty){
      selectedAccount = accounts[0].accountName;
    }
    setState(() {});
  }

  _getOutgoingCategoryList() async {
    outgoingCategory = [];
    if(widget.offline) {
      outgoingCategory = await DatabaseHelper.instance.getAllOutgoingCategory();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/outgoingcategorysdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));

      for (var element in response) {
        outgoingCategory.add(OutgoingCategory.fromMap(element));
      }
    }
    if(outgoingCategory.isNotEmpty){
      selectedCategory = outgoingCategory[0].outgoingCategoryName;  
    }
    setState(() {});
  }

  _getIncomeCategoryList() async {
    incomeCategory = [];
    if(widget.offline) {
      incomeCategory = await DatabaseHelper.instance.getAllIncomeCategory();
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/incomecategorysdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'}
      )).bodyBytes));

      for (var element in response) {
        incomeCategory.add(IncomeCategory.fromMap(element));
      }
    }
    if(incomeCategory.isNotEmpty){
      selectedCategory = incomeCategory[0].incomeCategoryName;
    }
    setState(() {});
  }
  
  _createTransaction(Transaction trs) async {
    if(widget.offline) {
      await DatabaseHelper.instance.createTransaction(trs);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(trs), status: 'create', tableName: 'transactions'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(trs), status: 'create', tableName: 'transactions'));
      } 
      String token = prefs.getString('auth_token')!;
      await http.post(
        Uri.parse("${global.URL_PREFIX}finance/transactionsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: trs.toJson()
      );
    }
    setState(() {});
  }
  
  @override
  void dispose() {
    dateController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Neue ${widget.transaction}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextFormField(
                  validator: (value){
                    if (value == null || value.isEmpty){
                      return 'Bitte gib eine gültiges Datum ein';
                    } else if(!value.contains(RegExp(r'^\s*(3[01]|[12][0-9]|0?[1-9])\.(1[012]|0?[1-9])\.((?:19|20)\d{2})\s*$'))){
                      return 'Bitte gib das Datum im gültigen Format ein: dd.MM.yyyy';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Datum',
                    hintText: 'dd.MM.yyyy'
                  ),
                  controller: dateController,
                  keyboardType: TextInputType.number,
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
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
                  ),
                  controller: descriptionController,
                ),
                DropdownButton(
                  value: selectedCategory,
                  items: widget.transaction == 'Einnahmen'?
                    incomeCategory.map((IncomeCategory ic){
                      return DropdownMenuItem(
                        value: ic.incomeCategoryName,
                        child: Text(ic.incomeCategoryName)
                      );
                    }).toList()
                    : outgoingCategory.map((OutgoingCategory oc){ 
                    return DropdownMenuItem(
                      value: oc.outgoingCategoryName.toString(),
                      child: Text(oc.outgoingCategoryName),
                    );
                  }).toList(), 
                  onChanged: (String? newValue){
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
                DropdownButton(
                  value: selectedAccount,
                  items: accounts.map((Account acc){
                      return DropdownMenuItem(
                        value: acc.accountName,
                        child: Text(acc.accountName)
                      );
                    }).toList(), 
                  onChanged: (String? newValue){  
                    setState(() {
                      selectedAccount = newValue!;
                    });
                  }
                ),
                ElevatedButton(
                  onPressed: (){
                    if (_formKey.currentState!.validate()){
                      var am = double.parse(amountController.text);
                      var tr = Transaction(
                        date: _dateFormat.parse(dateController.text), 
                        account: selectedAccount, 
                        amount: double.parse(am.toStringAsFixed(2)), 
                        category: selectedCategory, 
                        description: descriptionController.text, 
                        transactionkind: widget.transaction == 'Einnahmen' ? 'Einnahme' : 'Ausgabe',
                      );
                      _createTransaction(tr);
                      amountController.clear();
                      dateController.clear();
                      descriptionController.clear();
                      _formKey.currentState!.reset();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${widget.transaction} wurde erstellt'))
                      );
                    }
                  }, 
                  child: const Text('Submit'),
                )
              ],        
            ), 
          ),
        )
      ),
    );
  }
}