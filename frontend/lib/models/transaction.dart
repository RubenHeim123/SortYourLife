import 'dart:convert';
import 'dart:core';

import 'package:intl/intl.dart';

class Transaction {
  DateTime date;
  double amount;
  String category;
  String description;
  String account;
  String transactionkind;
  int? id;

  Transaction({required this.date, required this.amount, required this.category, required this.description, required this.account, required this.transactionkind, this.id});

  Transaction copyWith({
    DateTime? date,
    double? amount,
    String? category,
    String? description,
    String? account,
    String? transactionkind,
    int? id,
  }){
    return Transaction(
      date: date ?? this.date,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      account: account ?? this.account,
      transactionkind: transactionkind ?? this.transactionkind,
      id: id ?? this.id
    );
  }

  factory Transaction.fromMap(Map<String, dynamic> map){
    return Transaction(
      date: DateTime.parse(map['date']),
      amount: double.parse(map['amount']),
      category: map['category'],
      description: map['description'],
      account: map['account'],
      transactionkind: map['transactionkind'],
      id: map['id'],
    );
  }

  factory Transaction.fromOfflineMap(Map<String, dynamic> map){
    return Transaction(
      date: DateTime.parse(map['date']),
      amount: map['amount'],
      category: map['category'],
      description: map['description'],
      account: map['account'],
      transactionkind: map['transactionkind'],
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': DateFormat('yyyy-MM-dd').format(date),
      'amount': amount.toString(),
      'category': category,
      'description': description,
      'account': account,
      'transactionkind': transactionkind,
    };
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) =>
    Transaction.fromMap(json.decode(json.decode(source)));

}