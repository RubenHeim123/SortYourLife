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
import '../models/fixedtransaction.dart';
import '../models/update.dart';

class FixPage extends StatefulWidget {
  const FixPage({super.key, required this.offline});
  final bool offline;

  @override
  FixPageState createState() => FixPageState();
}

class FixPageState extends State<FixPage> {
  Client client = http.Client();
  List<FixedTransaction> trans = [];
  double yearCum = 0;
  double monthCum = 0;
  final transactionListKey = GlobalKey<FixPageState>();
  DateFormat dateFormat = DateFormat("dd.MM.yyyy");
  final global = Globals();
  Map<String, double> rythm = {'täglich':365,'wöchentlich':52.18,'monatlich':12,'vierteljährlich':4,'halbjährlich':2,'jährlich':1};

  @override
  void initState() {
    _getFixedTransactionList();
    super.initState();
  }

  _getFixedTransactionList() async {
    trans = [];
    yearCum = 0;
    if(widget.offline){
      trans = await DatabaseHelper.instance.getAllFixedTransaction();
      for(var element in trans){
        if(element.transactionkind == 'Einnahme' && element.category != 'Investition'){
          yearCum += (element.yearlyRate * rythm[element.payRythm]!);
        } else if(element.transactionkind == 'Ausgabe'){
          yearCum -= (element.yearlyRate * rythm[element.payRythm]!);
        }
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('auth_token')!;

      List response = json.decode(utf8.decode((await client.get(
        Uri.parse("${global.URL_PREFIX}finance/fixedtransactionsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token'},
      )).bodyBytes));

      for (var element in response) {
        var transaction = FixedTransaction.fromMap(element);
        trans.add(transaction);
        if(transaction.transactionkind == 'Einnahme' && transaction.category != 'Investition'){
          yearCum += (transaction.yearlyRate * rythm[transaction.payRythm]!);
        } else if(transaction.transactionkind == 'Ausgabe'){
          yearCum -= (transaction.yearlyRate * rythm[transaction.payRythm]!);
        }
      }
      trans.sort((a,b) => a.startDate.compareTo(b.startDate));
    } 
    monthCum = yearCum/12;
    setState(() {});
  }

  deleteFixedTransaction(ft) async {
    if(ft.transactionkind == 'Einnahme'){
      yearCum = yearCum - (ft.yearlyRate * rythm[ft.payRythm]);
    } else if(ft.transactionkind == 'Ausgabe'){
      yearCum = yearCum + (ft.yearlyRate * rythm[ft.payRythm]);
    }
    monthCum = yearCum/12;
    if(widget.offline){
      await DatabaseHelper.instance.deleteFixedTransaction(ft);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ft), status: 'delete', tableName: 'fixedtransactions'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ft), status: 'delete', tableName: 'fixedtransactions'));
      }
      String token = prefs.getString('auth_token')!;
      await client.delete(
        Uri.parse("${global.URL_PREFIX}finance/fixedtransactionsdetails/${ft.id}"),
        headers: <String, String>{'Authorization': 'Token $token'}
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: transactionListKey,
      appBar: AppBar(
        title: const Text('Daueraufträge'),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      body: RefreshIndicator(
        onRefresh: () async{
          _getFixedTransactionList();
        },
        child: Column(
          children:[
            const SizedBox(height: 25),
            yearCum >= 0 ? 
            Text('Jahres Betrag: ${yearCum.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))
            :Text('Jahres Betrag: ${yearCum.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            monthCum >= 0 ?
            Text('Monatlicher Betrag: ${monthCum.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))
            :Text('Monatlicher Betrag: ${monthCum.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: trans.length,
                itemBuilder: (BuildContext context, int index) {
                  return Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (BuildContext context) async{
                            await Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => FixedTransactionDetailPage(fixedtransaction: trans[index], transactionTyp: trans[index].transactionkind, offline: widget.offline)),
                            );
                            setState((){_getFixedTransactionList();});
                          },
                          backgroundColor: Colors.green,
                          icon: Icons.edit,
                          label: 'Bearbeiten',
                        ),
                        SlidableAction(
                          onPressed: (BuildContext context){
                            deleteFixedTransaction(trans[index]).whenComplete((){
                              setState((){
                                trans.removeAt(index);
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
                      child: trans[index].transactionkind == 'Einnahme' ?
                      ListTile(
                        title: Text(dateFormat.format(trans[index].startDate), style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${trans[index].category}: ${trans[index].yearlyRate.toStringAsFixed(2)} ${trans[index].payRythm}\n${trans[index].description}', style: const TextStyle(color: Colors.white)),
                      ) 
                      : ListTile(
                        title: Text(dateFormat.format(trans[index].startDate), style: const TextStyle(color: Colors.white)),
                        subtitle: Text('${trans[index].category}: -${trans[index].yearlyRate.toStringAsFixed(2)} ${trans[index].payRythm}\n${trans[index].description}', style: const TextStyle(color: Colors.white)),
                      ) 
                    ),
                  );
                },
              ),
            )
          ]
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => NewFixedTransactionPage(selectedTransactionkind: 'Ausgabe', offline: widget.offline)),
          ).then((value){setState(() {
            _getFixedTransactionList();
          });});
        },
        child: const Icon(Icons.add),
      ), 
    );
  }
}

class FixedTransactionDetailPage extends StatefulWidget {
  const FixedTransactionDetailPage({super.key, required this.fixedtransaction, required this.transactionTyp, required this.offline});
  final FixedTransaction fixedtransaction;
  final String transactionTyp;
  final bool offline;

  @override
  FixedTransactionDetailPageState createState() => FixedTransactionDetailPageState();
}

class FixedTransactionDetailPageState extends State<FixedTransactionDetailPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final yearlyRateController = TextEditingController();
  final startDateController = TextEditingController();
  final descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  List<OutgoingCategory> outgoingCategory = [];
  List<IncomeCategory> incomeCategory = [];
  List<Account> accounts = [];
  String selectedCategory = '';
  String selectedAccount = '';
  String selectedRythm = '';
  List<String> rythm = ['täglich','wöchentlich','monatlich','vierteljährlich','halbjährlich','jährlich'];
  final global = Globals();

  @override
  void initState() {
    if(widget.transactionTyp == 'Einnahme'){
      _getIncomeCategoryList();
    }else{
      _getOutgoingCategoryList();
    }
    _getAccountList();
    yearlyRateController.text = widget.fixedtransaction.yearlyRate.toString();
    startDateController.text = _dateFormat.format(widget.fixedtransaction.startDate);
    descriptionController.text = widget.fixedtransaction.description;
    selectedCategory = widget.fixedtransaction.category;
    selectedAccount = widget.fixedtransaction.account;
    selectedRythm = widget.fixedtransaction.payRythm;
    super.initState();    
  }

  _getAccountList() async {
    accounts = [];
    if(widget.offline){
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
    if(widget.offline){
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
    if(widget.offline){
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
  
  changeFixedTransaction(tr) async {
    if(widget.offline){
      await DatabaseHelper.instance.updateFixedTransaction(tr);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(FixedTransaction(account: widget.fixedtransaction.account, category: widget.fixedtransaction.category, description: widget.fixedtransaction.description, payRythm: widget.fixedtransaction.payRythm, startDate: widget.fixedtransaction.startDate, transactionkind: widget.transactionTyp, yearlyRate: widget.fixedtransaction.yearlyRate)), status: 'delete', tableName: 'fixedtransactions'));
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(tr), status: 'create', tableName: 'fixedtransactions'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(FixedTransaction(account: widget.fixedtransaction.account, category: widget.fixedtransaction.category, description: widget.fixedtransaction.description, payRythm: widget.fixedtransaction.payRythm, startDate: widget.fixedtransaction.startDate, transactionkind: widget.transactionTyp, yearlyRate: widget.fixedtransaction.yearlyRate)), status: 'delete', tableName: 'fixedtransactions'));
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(tr), status: 'create', tableName: 'fixedtransactions'));
      }
      String token = prefs.getString('auth_token')!;
      await client.put(
        Uri.parse("${global.URL_PREFIX}finance/fixedtransactionsdetails/${tr.id}"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: tr.toJson()
      );
    }
  }
  
  @override
  void dispose() {
    startDateController.dispose();
    yearlyRateController.dispose();
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
                    labelText: 'Start Datum',
                    hintText: 'dd.MM.yyyy'
                  ),
                  controller: startDateController,
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
                  controller: yearlyRateController,
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
                  items: widget.transactionTyp == 'Einnahme'?
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
                DropdownButton(
                  value: selectedRythm,
                  items: rythm.map((String value){
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(), 
                  onChanged: (String? newValue){  
                    setState(() {
                      selectedRythm = newValue!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()){
                      var am = double.parse(yearlyRateController.text);
                      var tr = FixedTransaction(
                        startDate: _dateFormat.parse(startDateController.text), 
                        account: selectedAccount, 
                        yearlyRate: double.parse(am.toStringAsFixed(2)), 
                        category: selectedCategory, 
                        description: descriptionController.text, 
                        transactionkind: widget.transactionTyp == 'Einnahme' ? 'Einnahme' : 'Ausgabe',
                        id: widget.fixedtransaction.id, 
                        payRythm: selectedRythm,
                      );
                      await changeFixedTransaction(tr);
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

class NewFixedTransactionPage extends StatefulWidget {
  const NewFixedTransactionPage({super.key, required this.selectedTransactionkind, required this.offline});
  final String selectedTransactionkind;
  final bool offline;

  @override
  NewFixedTransactionPageState createState() => NewFixedTransactionPageState();
}

class NewFixedTransactionPageState extends State<NewFixedTransactionPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final yearlyRateController = TextEditingController();
  final startDateController = TextEditingController();
  final descriptionController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  List<OutgoingCategory> outgoingCategory = [];
  List<IncomeCategory> incomeCategory = [];
  List<Account> accounts = [];
  String selectedCategory = '';
  String selectedAccount = '';
  String selectedRythm = 'monatlich';
  List<String> rythm = ['täglich','wöchentlich','monatlich','vierteljährlich','halbjährlich','jährlich'];
  List<String> transkind = ['Ausgabe','Einnahme'];
  final global = Globals();

  @override
  void initState() {
    if(widget.selectedTransactionkind == 'Einnahme'){
      _getIncomeCategoryList();
    } else if(widget.selectedTransactionkind == 'Ausgabe'){
      _getOutgoingCategoryList();
    }
    _getAccountList();
    super.initState();    
  }

  _getAccountList() async {
    accounts = [];
    if(widget.offline){
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
    if(widget.offline){
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
    if(widget.offline){
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
  
  _createFixedTransaction(FixedTransaction trs) async {
    if(widget.offline){
      await DatabaseHelper.instance.createFixedTransaction(trs);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(trs), status: 'create', tableName: 'fixedtransactions'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(trs), status: 'create', tableName: 'fixedtransactions'));
      }
      String token = prefs.getString('auth_token')!;
      await http.post(
        Uri.parse("${global.URL_PREFIX}finance/fixedtransactionsdetails/"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: trs.toJson()
      );
    }
    setState(() {});
  }
  
  @override
  void dispose() {
    startDateController.dispose();
    yearlyRateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Dauerauftrag'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton(
                  value: widget.selectedTransactionkind,
                  items: transkind.map((String value){
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(), 
                  onChanged: (String? newValue){  
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => NewFixedTransactionPage(selectedTransactionkind: newValue!, offline: widget.offline)),
                    );
                  },
                ),
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
                    labelText: 'Start Datum',
                    hintText: 'dd.MM.yyyy'
                  ),
                  controller: startDateController,
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
                  controller: yearlyRateController,
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
                  items: widget.selectedTransactionkind == 'Einnahme'?
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
                DropdownButton(
                  value: selectedRythm,
                  items: rythm.map((String value){
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(), 
                  onChanged: (String? newValue){  
                    setState(() {
                      selectedRythm = newValue!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: (){
                    if (_formKey.currentState!.validate()){
                      var am = double.parse(yearlyRateController.text);
                      var tr = FixedTransaction(
                        startDate: _dateFormat.parse(startDateController.text),
                        account: selectedAccount, 
                        yearlyRate: double.parse(am.toStringAsFixed(2)), 
                        category: selectedCategory, 
                        description: descriptionController.text, 
                        transactionkind: widget.selectedTransactionkind, 
                        payRythm: selectedRythm,
                      );
                      yearlyRateController.clear();
                      startDateController.clear();
                      descriptionController.clear();
                      _formKey.currentState!.reset();
                      _createFixedTransaction(tr);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('FixedTransaction wurde erstellt'))
                      );
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