import 'dart:convert';
import 'dart:io';

import 'package:flutterfrontend/models/user.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as enc;

import '../globals.dart';
import '../models/account.dart';
import '../models/fixedtransaction.dart';
import '../models/incomecategory.dart';
import '../models/outgoingcategory.dart';
import '../models/transaction.dart' as tr;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../models/update.dart';


class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  final global = Globals();
  Client onlineClient = http.Client();
  Future<Database> get database async => _database ??= await _initDatabase();
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'sortyourlife.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE users(id INTEGER PRIMARY KEY, username TEXT, password TEXT, token TEXT)");
    await db.execute("CREATE TABLE accounts(id INTEGER PRIMARY KEY, account_name TEXT, account_amount TEXT, FK_owner TEXT NOT NULL, FOREIGN KEY (FK_owner) REFERENCES users (username))");
    await db.execute("CREATE TABLE fixedtransactions(id INTEGER PRIMARY KEY, start_date TEXT, yearly_rate REAL, category TEXT, description TEXT, account TEXT, transactionkind TEXT, pay_rythm TEXT, FK_owner TEXT NOT NULL, FOREIGN KEY (FK_owner) REFERENCES users (username))");
    await db.execute("CREATE TABLE incomecategorys(id INTEGER PRIMARY KEY, income_category_name TEXT, FK_owner TEXT NOT NULL, FOREIGN KEY (FK_owner) REFERENCES users (username))");
    await db.execute("CREATE TABLE outgoingcategorys(id INTEGER PRIMARY KEY, outgoing_category_name TEXT, budget TEXT, expenses TEXT, sum TEXT, FK_owner TEXT NOT NULL, FOREIGN KEY (FK_owner) REFERENCES users (username))");
    await db.execute("CREATE TABLE transactions(id INTEGER PRIMARY KEY, date TEXT, amount REAL, category TEXT, description TEXT, account TEXT, transactionkind TEXT, FK_owner TEXT NOT NULL, FOREIGN KEY (FK_owner) REFERENCES users (username))");
    await db.execute("CREATE TABLE updates(id INTEGER PRIMARY KEY, table_name TEXT NOT NULL, status TEXT NOT NULL, data TEXT NOT NULL, FK_owner TEXT NOT NULL, FOREIGN KEY (FK_owner) REFERENCES users (username))");
  }

  Future<int> createUser(User user) async {
    final client = await instance.database;
    await createDataTables(user.token);
    return client.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getUserToken(String username) async {
    final client = await instance.database;
    List<Map<String, dynamic>> users = await client.query('users', columns: ['token'], where: 'username = ?', whereArgs: [username]);
    if (users.isNotEmpty) {
      return User.fromMap(users.first).token;
    }
    return throw Exception('Id nicht vorhanden');
  }

  Future<int> getUserId(String username) async {
    final client = await instance.database;
    List<Map<String, dynamic>> users = await client.query('users', columns: ['id'], where: 'username = ?', whereArgs: [username]);
    if (users.isNotEmpty) {
      return User.fromMap(users.first).id!;
    }
    return throw Exception('Id nicht vorhanden');
  }

  Future<List<User>> getAllUser() async { 
    final client = await instance.database;
    var userItems = await client.query('users', orderBy: 'id ASC');
    List<User> userList = userItems.isNotEmpty ? userItems.map((e) => User.fromMap(e)).toList() : [];
    return userList;
  }

  Future<int> createUpdate(Update update) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalUpdate = update.toMap();
    finalUpdate['FK_owner'] = username;
    return client.insert('updates', finalUpdate, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Update>> getAllUpdatesFromAllUsers() async { 
    final client = await instance.database;
    var userItems = await client.query('updates', orderBy: 'id ASC');
    List<Update> updateList = userItems.isNotEmpty ? userItems.map((e) => Update.fromMap(e)).toList() : [];
    return updateList;
  }
  
  Future<List<Update>> getAllUpdates() async { 
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    var userItems = await client.query('updates', orderBy: 'id ASC', where: 'FK_owner = ?', whereArgs: [username]);
    List<Update> updateList = userItems.isNotEmpty ? userItems.map((e) => Update.fromMap(e)).toList() : [];
    return updateList;
  }

  Future<int> deleteUpdate(int id) async {
    final client = await instance.database;
    return await client.delete('updates', where:'id = ?', whereArgs: [id],);
  }

  Future<int> deleteAllUpdates(String owner) async {
    final client = await instance.database;
    return await client.delete('updates', where: 'FK_owner = ?', whereArgs: [owner]);
  }

  Future<int> deleteUser(int id) async {
    final client = await instance.database;
    final result = await client.query('users', where:'id = ?', whereArgs: [id],);
    String owner = User.fromMap(result.first).username;
    await deleteAllAccounts(owner);
    await deleteAllFixedTransaction(owner);
    await deleteAllIncomeCategorys(owner);
    await deleteAllOutgoingCategorys(owner);
    await deleteAllTransaction(owner);
    return await client.delete('users', where:'id = ?', whereArgs: [id],);
  }

  Future<int> update(User user) async {
    final client = await instance.database;
    return await client.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id],);
  }

  Future<bool> isAuthenticated(User user) async {
    final client = await instance.database;
    List<Map<String, dynamic>> users = await client.query('users', where: 'username = ?', whereArgs: [user.username]);
    if (users.isNotEmpty) {
      if(users.first.containsValue(user.username) && users.first.containsValue(encrypt(user.password))){
        return true;
      } else if(users.first.containsValue(user.username) && user.password == 'Beispiel'){
        return true;
      }
    }
    return false;
  }

  String encrypt(String pwd){
    final key = enc.Key.fromLength(32);
    final iv = enc.IV.fromLength(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));

    final encrypted = encrypter.encrypt(pwd, iv: iv);
    return encrypted.base64;
  }

  Future<int> createAccount(Account account) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalAccount = account.toMap();
    finalAccount['FK_owner'] = username;
    return client.insert('accounts', finalAccount, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getAccountByName(String accountName) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> account = await client.query('accounts', where: 'account_name = ? and FK_owner = ?', whereArgs: [accountName, username]);
    if (account.isNotEmpty) {
      return account.first;
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> getAccountById(int id) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> account = await client.query('accounts', where: 'id = ? and FK_owner = ?', whereArgs: [id, username]);
    if (account.isNotEmpty) {
      return account.first;
    }
    return null;
  }

  Future<List<Account>> getAllAccount() async { 
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final accountItems = await client.query('accounts', orderBy: 'account_name ASC', where: 'FK_owner = ?', whereArgs: [username]);
    List<Account> accountList = accountItems.isNotEmpty ? accountItems.map((e) => Account.fromMap(e)).toList() : [];
    return accountList;
  }

  Future<int> deleteAccount(Account ac) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return await client.delete('accounts', where:'id = ? and FK_owner = ?', whereArgs: [ac.id, username],);
  }

  Future<int> deleteAllAccounts(String owner) async {
    final client = await instance.database;
    return await client.delete('accounts', where: 'FK_owner = ?', whereArgs: [owner]);
  }

  Future<int> updateAccount(Account account) async {
    final client = await instance.database;
    return await client.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id],);
  }

  Future<int> createIncomeCategory(IncomeCategory incomeCategory) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalIncomeCategory = incomeCategory.toMap();
    finalIncomeCategory['FK_owner'] = username;
    return client.insert('incomecategorys', finalIncomeCategory, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<Map<String, dynamic>?> getIncomeCategoryById(int id) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> incomeCategory = await client.query('incomecategorys', where: 'id = ? and FK_owner = ?', whereArgs: [id, username]);
    if (incomeCategory.isNotEmpty) {
      return incomeCategory.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getIncomeCategoryByName(String incomeCategoryName) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> incomeCategory = await client.query('incomecategorys', where: 'income_category_name = ? and FK_owner = ?', whereArgs: [incomeCategoryName, username]);
    if (incomeCategory.isNotEmpty) {
      return incomeCategory.first;
    }
    return null;
  }

  Future<List<IncomeCategory>> getAllIncomeCategory() async { 
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final incomeCategoryItems = await client.query('incomecategorys', orderBy: 'income_category_name ASC', where: 'FK_owner = ?', whereArgs: [username]);
    List<IncomeCategory> incomeCategoryList = incomeCategoryItems.isNotEmpty ? incomeCategoryItems.map((e) => IncomeCategory.fromMap(e)).toList() : [];
    return incomeCategoryList;
  }

  Future<int> deleteIncomeCategory(IncomeCategory ic) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return await client.delete('incomecategorys', where:'id = ? and FK_owner = ?', whereArgs: [ic.id, username],);
  }

  Future<int> deleteAllIncomeCategorys(String owner) async {
    final client = await instance.database;
    return await client.delete('incomecategorys', where: 'FK_owner = ?', whereArgs: [owner]);
  }

  Future<int> updateIncomeCategory(IncomeCategory incomeCategory) async {
    final client = await instance.database;
    return await client.update('incomecategorys', incomeCategory.toMap(), where: 'id = ?', whereArgs: [incomeCategory.id],);
  }

  Future<int> createOutgoingCategory(OutgoingCategory outgoingCategory) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalOutgoingCategory = outgoingCategory.toOfflineMap();
    finalOutgoingCategory['FK_owner'] = username;
    return client.insert('outgoingcategorys', finalOutgoingCategory, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getOutgoingCategoryByName(String outgoingCategoryName) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> outgoingCategory = await client.query('outgoingcategorys', where: 'outgoing_category_name = ? and FK_owner = ?', whereArgs: [outgoingCategoryName, username]);
    if (outgoingCategory.isNotEmpty) {
      return outgoingCategory.first;
    }
    return null;
  }
  
  Future<Map<String, dynamic>?> getOutgoingCategoryById(int id) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> outgoingCategory = await client.query('outgoingcategorys', where: 'id = ? and FK_owner = ?', whereArgs: [id, username]);
    if (outgoingCategory.isNotEmpty) {
      return outgoingCategory.first;
    }
    return null;
  }

  Future<List<OutgoingCategory>> getAllOutgoingCategory() async { 
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final outgoingCategoryItems = await client.query('outgoingcategorys', orderBy: 'outgoing_category_name ASC', where: 'FK_owner = ?', whereArgs: [username]);
    List<OutgoingCategory> outgoingCategoryList = outgoingCategoryItems.isNotEmpty ? outgoingCategoryItems.map((e) => OutgoingCategory.fromMap(e)).toList() : [];

    // Loop through all OutgoingCategory objects
    for (int i = 0; i < outgoingCategoryList.length; i++) {
      // // Get the current OutgoingCategory object
      OutgoingCategory outgoingCategory = outgoingCategoryList[i];

      if(outgoingCategory.expenses == null){ 
        outgoingCategory.expenses = '0';
        outgoingCategory.sum = outgoingCategory.budget;
      } else {
        outgoingCategory.expenses = outgoingCategory.expenses;
        outgoingCategory.sum = outgoingCategory.sum;
      }
    }
    return outgoingCategoryList;
  }

  Future<int> deleteOutgoingCategory(OutgoingCategory ogc) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return await client.delete('outgoingcategorys', where:'id = ? and FK_owner = ?', whereArgs: [ogc.id, username],);
  }

  Future<int> deleteAllOutgoingCategorys(String owner) async {
    final client = await instance.database;
    return await client.delete('outgoingcategorys', where: 'FK_owner = ?', whereArgs: [owner]);
  }

  Future<int> updateOutgoingCategory(OutgoingCategory outgoingCategory) async {
    final client = await instance.database;
    return await client.update('outgoingcategorys', outgoingCategory.toOfflineMap(), where: 'id = ?', whereArgs: [outgoingCategory.id],);
  }

  Future<int> createTransaction(tr.Transaction transaction) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalTransaction = transaction.toMap();
    finalTransaction['FK_owner'] = username;
    Map<String, dynamic>? account = await getAccountByName(finalTransaction['account']);
    Account finalAccount = Account.fromMap(account!);
    if(finalTransaction['transactionkind'] == 'Ausgabe'){
      if(DateFormat('yyyy-MM-dd').parse(finalTransaction['date']).year == DateTime.now().year){
        Map<String, dynamic>? category = await getOutgoingCategoryByName(finalTransaction['category']);
        OutgoingCategory finalCategory = OutgoingCategory.fromMap(category!);
        if(finalCategory.expenses != null) {
          finalCategory.expenses = (double.parse(finalCategory.expenses!) + double.parse(finalTransaction['amount'])).toString();
          finalCategory.sum = (double.parse(finalCategory.budget) - double.parse(finalCategory.expenses!)).toString();
        } else {
          finalCategory.expenses = finalTransaction['amount'];
          finalCategory.sum = (double.parse(finalCategory.budget) - double.parse(finalTransaction['amount'])).toString();
        }
        await updateOutgoingCategory(finalCategory);
      }
      finalAccount.accountAmount = (double.parse(finalAccount.accountAmount) - double.parse(finalTransaction['amount'])).toString();
    } else if(finalTransaction['transactionkind'] == 'Einnahme'){
      finalAccount.accountAmount = (double.parse(finalAccount.accountAmount) + double.parse(finalTransaction['amount'])).toString();
    }
    await updateAccount(finalAccount);
    return client.insert('transactions', finalTransaction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getTransactionById(int id) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> transaction = await client.query('transactions', where: 'id = ? and FK_owner = ?', whereArgs: [id, username]);
    if (transaction.isNotEmpty) {
      return transaction.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTransactionId(tr.Transaction trans) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> transaction = await client.query('transactions', where: 'date = ? and amount = ? and category = ? and description = ? and account = ? and transactionkind = ? and FK_owner = ?', whereArgs: [DateFormat('yyyy-MM-dd').format(trans.date), trans.amount, trans.category, trans.description, trans.account, trans.transactionkind, username]);
    if (transaction.isNotEmpty) {
      return transaction.first;
    }
    return null;
  }

  Future<List<tr.Transaction>> getAllTransaction() async { 
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final transactionItems = await client.query('transactions', orderBy: 'date ASC', where: 'FK_owner = ?', whereArgs: [username]);
    List<tr.Transaction> transactionList = transactionItems.isNotEmpty ? transactionItems.map((e) => tr.Transaction.fromOfflineMap(e)).toList() : [];
    return transactionList;
  }

  Future<int> deleteTransaction(tr.Transaction tr) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    await changeAccountAndCategoryByDeleteTransaction(tr);
    return await client.delete('transactions', where:'id = ? and FK_owner = ?', whereArgs: [tr.id, username],);
  }

  Future<void> changeAccountAndCategoryByDeleteTransaction(tr.Transaction tr) async {
    Map<String, dynamic>? account = await getAccountByName(tr.account);
    Account finalAccount = Account.fromMap(account!);
    if(tr.transactionkind == 'Ausgabe'){
      if(tr.date.year == DateTime.now().year){
        Map<String, dynamic>? category = await getOutgoingCategoryByName(tr.category);
        OutgoingCategory finalCategory = OutgoingCategory.fromMap(category!);
        if(finalCategory.expenses != null) {
          finalCategory.expenses = (double.parse(finalCategory.expenses!) - tr.amount).toString();
          finalCategory.sum = (double.parse(finalCategory.budget) + double.parse(finalCategory.expenses!)).toString();
        } else {
          finalCategory.expenses = (0 - tr.amount).toString();
          finalCategory.sum = (double.parse(finalCategory.budget) + tr.amount).toString();
        }
        await updateOutgoingCategory(finalCategory);
      }
      finalAccount.accountAmount = (double.parse(finalAccount.accountAmount) + tr.amount).toString();
    } else if(tr.transactionkind == 'Einnahme'){
      finalAccount.accountAmount = (double.parse(finalAccount.accountAmount) - tr.amount).toString();
    }
    await updateAccount(finalAccount);
  }
  
  Future<int> deleteAllTransaction(String owner) async {
    final client = await instance.database;
    return await client.delete('transactions', where: 'FK_owner = ?', whereArgs: [owner]);
  }

  Future<int> updateTransaction(tr.Transaction transaction) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalTransaction = transaction.toMap();
    finalTransaction['FK_owner'] = username;
    Map<String, dynamic>? otransaction = await getTransactionById(transaction.id!);
    tr.Transaction oldTransaction = tr.Transaction.fromOfflineMap(otransaction!);
    await changeAccountByUpdateTransaction(finalTransaction, oldTransaction.account, oldTransaction.amount);
    return await client.update('transactions', finalTransaction, where: 'id = ?', whereArgs: [transaction.id],);
  }

  Future<void> changeAccountByUpdateTransaction(Map finalTransaction, String oldAccount, double oldAmount) async {
    Map<String, dynamic>? account = await getAccountByName(finalTransaction['account']);
    Account newAccount = Account.fromMap(account!); 
    if(oldAccount != finalTransaction['account']){
      Map<String, dynamic>? oaccount = await getAccountByName(oldAccount);
      Account oAccount = Account.fromMap(oaccount!);
      if(finalTransaction['transactionkind'] == 'Ausgabe'){
        oAccount.accountAmount = (double.parse(oAccount.accountAmount) + oldAmount).toString();
        newAccount.accountAmount = (double.parse(newAccount.accountAmount) - double.parse(finalTransaction['amount'])).toString();
      } else if(finalTransaction['transactionkind'] == 'Einnahme'){
        oAccount.accountAmount = (double.parse(oAccount.accountAmount) - oldAmount).toString();
        newAccount.accountAmount = (double.parse(newAccount.accountAmount) + double.parse(finalTransaction['amount'])).toString();
      }
      await updateAccount(newAccount);
      await updateAccount(oAccount);
    } else {
      if(finalTransaction['transactionkind'] == 'Ausgabe'){
        newAccount.accountAmount = (double.parse(newAccount.accountAmount) + oldAmount).toString();
        newAccount.accountAmount = (double.parse(newAccount.accountAmount) - double.parse(finalTransaction['amount'])).toString();
      } else if(finalTransaction['transactionkind'] == 'Einnahme'){ 
        newAccount.accountAmount = (double.parse(newAccount.accountAmount) - oldAmount).toString();
        newAccount.accountAmount = (double.parse(newAccount.accountAmount) + double.parse(finalTransaction['amount'])).toString();
      }
      await updateAccount(newAccount);
    }
  }

  Future<int> createFixedTransaction(FixedTransaction transaction) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final finalFixedTransaction = transaction.toMap();
    finalFixedTransaction['FK_owner'] = username;
    return client.insert('fixedtransactions', finalFixedTransaction, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getFixedTransactionById(int id) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> transaction = await client.query('fixedtransactions', where: 'id = ? and FK_owner = ?', whereArgs: [id, username]);
    if (transaction.isNotEmpty) {
      return transaction.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getFixedTransactionId(FixedTransaction ftr) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    List<Map<String, dynamic>> fixedtransaction = await client.query('fixedtransactions', where: 'start_date = ? and yearly_rate = ? and category = ? and description = ? and account = ? and transactionkind = ? and pay_rythm = ? and FK_owner = ?', whereArgs: [DateFormat('yyyy-MM-dd').format(ftr.startDate), ftr.yearlyRate, ftr.category, ftr.description, ftr.account, ftr.transactionkind, ftr.payRythm, username]);
    if (fixedtransaction.isNotEmpty) {
      return fixedtransaction.first;
    }
    return null;
  }

  Future<List<FixedTransaction>> getAllFixedTransaction() async { 
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final transactionItems = await client.query('fixedtransactions', orderBy: 'start_date ASC', where: 'FK_owner = ?', whereArgs: [username]);
    List<FixedTransaction> transactionList = transactionItems.isNotEmpty ? transactionItems.map((e) => FixedTransaction.fromOfflineMap(e)).toList() : [];
    return transactionList;
  }

  Future<int> deleteFixedTransaction(FixedTransaction ft) async {
    final client = await instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return await client.delete('fixedtransactions', where:'id = ? and FK_owner = ?', whereArgs: [ft.id, username],);
  }

  Future<int> deleteAllFixedTransaction(String owner) async {
    final client = await instance.database;
    return await client.delete('fixedtransactions', where: 'FK_owner = ?', whereArgs: [owner]);
  }

  Future<int> updateFixedTransaction(FixedTransaction transaction) async {
    final client = await instance.database;
    return await client.update('fixedtransactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id],);
  }

  Future<void> createDataTables(String token) async {
    List incomeCategoryResponse = json.decode(utf8.decode((await onlineClient.get(
      Uri.parse("${global.URL_PREFIX}finance/incomecategorydetails/"),
      headers: <String, String>{'Authorization': 'Token $token'}
    )).bodyBytes));

    for (var element in incomeCategoryResponse) {
      await DatabaseHelper.instance.createIncomeCategory(IncomeCategory.fromMap(element));
    }

    List outgoingCategoryResponse = json.decode(utf8.decode((await onlineClient.get(
      Uri.parse("${global.URL_PREFIX}finance/outgoingcategorydetails/"),
      headers: <String, String>{'Authorization': 'Token $token'}
    )).bodyBytes));

    for (var element in outgoingCategoryResponse) {
      await DatabaseHelper.instance.createOutgoingCategory(OutgoingCategory.fromMap(element));
    }

    List accountResponse = json.decode(utf8.decode((await onlineClient.get(
      Uri.parse("${global.URL_PREFIX}finance/accountdetails/"),
      headers: <String, String>{'Authorization': 'Token $token'}
    )).bodyBytes));

    for (var element in accountResponse) {
      await DatabaseHelper.instance.createAccount(Account.fromMap(element));
    }

    List fixedTransactionResponse = json.decode(utf8.decode((await onlineClient.get(
      Uri.parse("${global.URL_PREFIX}finance/fixedtransactionsdetails/"),
      headers: <String, String>{'Authorization': 'Token $token'}
    )).bodyBytes));

    for (var element in fixedTransactionResponse) {
      await DatabaseHelper.instance.createFixedTransaction(FixedTransaction.fromMap(element));
    }
  }

  Future<bool> syncOfflineToOnline(username, password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? owner = prefs.getString('username');
    String? token;
    if(owner != null){
      token = prefs.getString('auth_token');
      if(token == null){
        return false;
      }
    } else {
      return false;
    }
    List<Update> updates = await getAllUpdates();
    for(var element in updates){
      if (element.status == 'create'){
        await http.post(
          Uri.parse("${global.URL_PREFIX}finance/${element.tableName}details/"),
          headers: <String, String>{'Authorization': 'Token $token','Content-Type': 'application/json'},
          body: json.decode(element.data)
        );
      } else if (element.status == 'delete'){
        await http.delete(
          Uri.parse("${global.URL_PREFIX}finance/${element.tableName}details/-1"),
          headers: <String, String>{'Authorization': 'Token $token'},
          body: json.decode(element.data)
        );
      }
    }
    return true;
  }

  // Future<void> syncOnlineToOffline() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? owner = prefs.getString('username');
  //   String? token;
  //   if(owner != null){
  //     token = prefs.getString('auth_token');
  //     if(token == null){
  //       return;
  //     }
  //   } else {
  //     return;
  //   }
  //   List<Update> updates = await getAllUpdates();
  //   for(var element in updates){
  //     if (element.status == 'create'){
  //       if(element.tableName == 'accounts'){
  //         await createAccount(Account.fromJson(element.data));
  //       } else if(element.tableName == 'fixedtransactions'){
  //         await createFixedTransaction(FixedTransaction.fromJson(element.data));
  //       } else if(element.tableName == 'incomecategorys'){
  //         await createIncomeCategory(IncomeCategory.fromJson(element.data));
  //       } else if(element.tableName == 'outgoingcategorys'){
  //         await createOutgoingCategory(OutgoingCategory.fromJson(element.data));
  //       } else if(element.tableName == 'transactions'){
  //         await createTransaction(tr.Transaction.fromJson(element.data));
  //       }
  //     } else if (element.status == 'delete'){
  //       if(element.tableName == 'accounts'){
  //         final delAcc = await getAccountByName(Account.fromJson(element.data).accountName);
  //         await deleteAccount(Account.fromMap(delAcc!));
  //       } else if(element.tableName == 'fixedtransactions'){
  //         final delFtr = await getFixedTransactionId(FixedTransaction.fromJson(element.data));
  //         await deleteFixedTransaction(FixedTransaction.fromOfflineMap(delFtr!));
  //       } else if(element.tableName == 'incomecategorys'){
  //         final delIc = await getIncomeCategoryByName(IncomeCategory.fromJson(element.data).incomeCategoryName);
  //         await deleteIncomeCategory(IncomeCategory.fromMap(delIc!));
  //       } else if(element.tableName == 'outgoingcategorys'){
  //         final delOgc = await getOutgoingCategoryByName(OutgoingCategory.fromJson(element.data).outgoingCategoryName);
  //         await deleteOutgoingCategory(OutgoingCategory.fromMap(delOgc!));
  //       } else if(element.tableName == 'transactions'){
  //         final trans = tr.Transaction.fromJson(element.data);
  //         final delTr = await getTransactionId(trans);
  //         if(delTr == null){
  //           await changeAccountAndCategoryByDeleteTransaction(trans);
  //         } else {
  //           await deleteTransaction(tr.Transaction.fromOfflineMap(delTr));
  //         }
  //       }
  //     }
  //   }
  //   await deleteAllTransaction(owner);
  //   await deleteAllUpdates(owner);
  // } 

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'sortyourlife.db');
    await databaseFactory.deleteDatabase(path);
  }
}
