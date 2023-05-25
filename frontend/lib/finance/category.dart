import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../general/databasehelper.dart';
import '../general/navigationdrawer.dart' as m;
import '../globals.dart';
import '../models/account.dart';
import '../models/incomecategory.dart';
import '../models/outgoingcategory.dart';
import '../models/update.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.value, required this.offline});
  final String value;
  final bool offline;

  @override
  CategoryPageState createState() => CategoryPageState();
}

class CategoryPageState extends State<CategoryPage> {
  Client client = http.Client();
  List<OutgoingCategory> outgoingCategory = [];
  List<IncomeCategory> incomeCategory = [];
  final categoryListKey = GlobalKey<CategoryPageState>();
  late String _dropdownValue;
  final global = Globals();

  @override
  void initState() {
    _getIncomeCategoryList();
    _dropdownValue = widget.value;
    super.initState();
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
      outgoingCategory.sort((a,b) => a.outgoingCategoryName.compareTo(b.outgoingCategoryName));
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
      incomeCategory.sort((a,b) => a.incomeCategoryName.compareTo(b.incomeCategoryName));
    }
    setState(() {});
  }

  deleteIncomeCategory(ca) async {
    if(widget.offline){
      await DatabaseHelper.instance.deleteIncomeCategory(ca);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'delete', tableName: 'incomecategorys'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'delete', tableName: 'incomecategorys'));
      }
      String token = prefs.getString('auth_token')!;
      await client.delete(
        Uri.parse("${global.URL_PREFIX}finance/incomecategorysdetails/${ca.id}"),
        headers: <String, String>{'Authorization': 'Token $token'}
      );
    }
  }

  deleteOutgoingCategory(ca) async {
    if(widget.offline){
      await DatabaseHelper.instance.deleteOutgoingCategory(ca);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'delete', tableName: 'outgoingcategorys'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'delete', tableName: 'outgoingcategorys'));
      }
      String token = prefs.getString('auth_token')!;
      await client.delete(
        Uri.parse("${global.URL_PREFIX}finance/outgoingcategorysdetails/${ca.id}"),
        headers: <String, String>{'Authorization': 'Token $token'}
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: categoryListKey,
      appBar: AppBar(
        title: Text('$_dropdownValue Kategorien'),
      ),
      drawer: m.NavigationDrawer(offline: widget.offline),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton(
                  items: const [
                    DropdownMenuItem(value: 'Einnahmen', child: Text('Einnahmen')),
                    DropdownMenuItem(value: 'Ausgaben', child: Text('Ausgaben')),
                  ],
                  value: _dropdownValue,
                  onChanged: (selectedValue){
                    if(selectedValue is String){
                      
                      if (selectedValue == 'Einnahmen'){
                        _getIncomeCategoryList();
                      } else{
                        _getOutgoingCategoryList();
                      }
                      setState(() {
                        _dropdownValue = selectedValue;
                      });
                    }
                  },
                ),
              ]
            ),
            _dropdownValue == 'Einnahmen'?
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: incomeCategory.length,
              itemBuilder: (BuildContext context, int index) {
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (BuildContext context) async{
                          await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => CategoryDetailPage(category: incomeCategory[index], value: 'Einnahmen', offline: widget.offline)),
                          );
                          setState((){_getIncomeCategoryList();});
                        },
                        backgroundColor: Colors.green,
                        icon: Icons.edit,
                        label: 'Bearbeiten',
                      ),
                      SlidableAction(
                        onPressed: (BuildContext context){
                          deleteIncomeCategory(incomeCategory[index]).whenComplete((){
                            setState((){
                              incomeCategory.removeAt(index);
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
                      title: Text(incomeCategory[index].incomeCategoryName, style: const TextStyle(color: Colors.white))
                    )
                  )
                );
              },
            )
            : ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: outgoingCategory.length,
              itemBuilder: (BuildContext context, int index) {
                return Slidable(
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (BuildContext context) async{
                          await Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => CategoryDetailPage(category: outgoingCategory[index], value: 'Ausgaben', offline: widget.offline)),
                          );
                          setState((){_getOutgoingCategoryList();});
                        },
                        backgroundColor: Colors.green,
                        icon: Icons.edit,
                        label: 'Bearbeiten',
                      ),
                      SlidableAction(
                        onPressed: (BuildContext context){
                          deleteOutgoingCategory(outgoingCategory[index]).whenComplete((){
                            setState((){
                              outgoingCategory.removeAt(index);
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
                      title: Text(outgoingCategory[index].outgoingCategoryName, style: const TextStyle(color: Colors.white)),
                      subtitle: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text('Budget: ${outgoingCategory[index].budget}', style: const TextStyle(color: Colors.white)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('Kosten: ${outgoingCategory[index].expenses!}',  style: const TextStyle(color: Colors.red)),
                          ),
                          double.parse(outgoingCategory[index].sum!) >= 0 ?
                          Expanded(
                            flex: 1,
                            child: Text('Summe: ${outgoingCategory[index].sum!}', style: const TextStyle(color: Colors.green)),
                          )
                          : Expanded(
                            flex: 1,
                            child: Text('Summe: ${outgoingCategory[index].sum!}', style: const TextStyle(color: Colors.red)),
                          )
                        ],
                      ),
                    )
                  )
                );
              },
            )
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => NewCategoryPage(value: _dropdownValue, offline: widget.offline)),
          ).then((value){setState(() {
            _dropdownValue == 'Einnahmen'?
            _getIncomeCategoryList()
            :_getOutgoingCategoryList();
          });});
        },
        child: const Icon(Icons.add),
      ), 
    );
  }
}

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({super.key, required this.value, required this.category, required this.offline});
  final category;
  final String value;
  final bool offline;

  @override
  CategoryDetailPageState createState() => CategoryDetailPageState();
}

class CategoryDetailPageState extends State<CategoryDetailPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final budgetController = TextEditingController();
  final nameController = TextEditingController();
  final global = Globals();

  @override
  void initState() {
    super.initState();   
     if(widget.category.runtimeType == IncomeCategory){
    nameController.text = widget.category.incomeCategoryName;
     }else{
      nameController.text = widget.category.outgoingCategoryName;
      budgetController.text = widget.category.budget;
     }
  }  

  changeIncomeCategory(ca) async {
    if(widget.offline){ 
      await DatabaseHelper.instance.updateIncomeCategory(ca);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(IncomeCategory(incomeCategoryName: widget.category.incomeCategoryName)), status: 'delete', tableName: 'incomecategorys'));
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'create', tableName: 'incomecategorys'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(IncomeCategory(incomeCategoryName: widget.category.incomeCategoryName)), status: 'delete', tableName: 'incomecategorys'));
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'create', tableName: 'incomecategorys'));
      }
      String token = prefs.getString('auth_token')!;
      await client.put(
        Uri.parse("${global.URL_PREFIX}finance/incomecategorysdetails/${ca.id}"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: ca.toJson()
      );
    }
  }
  
  changeOutgoingCategory(ca) async {
    if(widget.offline){
      await DatabaseHelper.instance.updateOutgoingCategory(ca);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(OutgoingCategory(outgoingCategoryName: widget.category.outgoingCategoryName, budget: widget.category.budget)), status: 'delete', tableName: 'outgoingcategorys'));
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'create', tableName: 'outgoingcategorys'));
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(OutgoingCategory(outgoingCategoryName: widget.category.outgoingCategoryName, budget: widget.category.budget)), status: 'delete', tableName: 'outgoingcategorys'));
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ca), status: 'create', tableName: 'outgoingcategorys'));
      }
      String token = prefs.getString('auth_token')!;
      await client.put(
        Uri.parse("${global.URL_PREFIX}finance/outgoingcategorysdetails/${ca.id}"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: ca.toJson()
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorie Änderung'),
      ),
      body: Column(
        children: [
          widget.value == 'Einnahmen'?
          Expanded(
            child: SingleChildScrollView(
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
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()){
                            var ic = IncomeCategory(
                              incomeCategoryName: nameController.text,
                              id: widget.category.id,
                            );
                            await changeIncomeCategory(ic);
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
            )
          )
          :Expanded(
            child: SingleChildScrollView(
              child:Padding(
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
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()){
                            var am = double.parse(budgetController.text);
                            var ogc = OutgoingCategory(
                              outgoingCategoryName: nameController.text,
                              budget: am.toStringAsFixed(2),
                              id: widget.category.id,
                            );
                            await changeOutgoingCategory(ogc);
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
          )
        ]
      ),
    );
  }
}

class NewCategoryPage extends StatefulWidget {
  const NewCategoryPage({super.key, required this.value, required this.offline});
  final String value;
  final bool offline;

  @override
  NewCategoryPageState createState() => NewCategoryPageState();
}

class NewCategoryPageState extends State<NewCategoryPage> {
  Client client = http.Client();
  final _formKey = GlobalKey<FormState>();  
  final budgetController = TextEditingController();
  final nameController = TextEditingController();
  List<Account> accounts = [];
  List<String> list = <String>['Einnahmen', 'Ausgaben'];
  late String selectedCategory = widget.value;
  final global = Globals();

  @override
  void initState() {
    super.initState();    
  }

  Future<bool> _createIncomeCategory(IncomeCategory ic)async {
    if(widget.offline){
      await DatabaseHelper.instance.createIncomeCategory(ic);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ic), status: 'create', tableName: 'incomecategorys'));
      return true;
    }else{
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ic), status: 'create', tableName: 'incomecategorys'));
      }
      String token = prefs.getString('auth_token')!;
      final response = await http.post(
        Uri.parse("${global.URL_PREFIX}finance/incomecategorysdetails/"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: ic.toJson()
      );
      if(response.statusCode == 200){
        return true;
      }
    }
    setState(() {});
    return false;
  }
  
  Future<bool> _createOutgoingCategory(OutgoingCategory ogc)async {
    if(widget.offline){
      await DatabaseHelper.instance.createOutgoingCategory(ogc);
      await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ogc), status: 'create', tableName: 'outgoingcategorys'));
      return true;
    }else{
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasOfflineDatabase = prefs.getBool('hasOfflineDatabase')!;
      if(hasOfflineDatabase){
        await DatabaseHelper.instance.createUpdate(Update(data: json.encode(ogc), status: 'create', tableName: 'outgoingcategorys'));
      }
      String token = prefs.getString('auth_token')!;
      final response = await http.post(
        Uri.parse("${global.URL_PREFIX}finance/outgoingcategorysdetails/"),
        headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
        body: ogc.toJson()
      );
      if(response.statusCode == 200){
        return true;
      }
    }
    setState(() {});
    return false;
  }

  @override
  void dispose() {
    nameController.dispose();
    budgetController.dispose();
    super.dispose();
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Kategorie'),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton(
                value: selectedCategory,
                items: list.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) { 
                  setState((){
                    selectedCategory = value!;
                  });
                }, 
              ),
            ]
          ),
          selectedCategory == 'Einnahmen'?
          Expanded(
            child: SingleChildScrollView(
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
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()){
                            var ic = IncomeCategory(
                              incomeCategoryName: nameController.text,
                            );
                            final success = await _createIncomeCategory(ic);
                            _formKey.currentState!.reset();
                            nameController.clear();
                            if(success){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${ic.incomeCategoryName} wurde angelegt')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${ic.incomeCategoryName} wurde nicht angelegt')),
                              );
                            }
                          }
                        }, 
                        child: const Text('Submit'),
                      )
                    ],       
                  ), 
                ),
              ),
            )
          )
          :Expanded(
            child: SingleChildScrollView(
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
                        controller: budgetController,
                        keyboardType: TextInputType.number,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()){
                            var am = double.parse(budgetController.text);
                            var ogc = OutgoingCategory(
                              outgoingCategoryName: nameController.text,
                              budget: am.toStringAsFixed(2),
                            );
                            final success = await _createOutgoingCategory(ogc);
                            nameController.clear();
                            budgetController.clear();
                            _formKey.currentState!.reset();
                            if(success){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${ogc.outgoingCategoryName} wurde angelegt')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${ogc.outgoingCategoryName} wurde nicht angelegt')),
                              );
                            }
                          }
                        }, 
                        child: const Text('Submit'),
                      )
                    ],        
                  ), 
                ),
              )
            )
          )
        ]
      ),
    );
  }
}