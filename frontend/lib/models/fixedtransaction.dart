import 'dart:convert';
import 'dart:core';

import 'package:intl/intl.dart';

class FixedTransaction {
  DateTime startDate;
  double yearlyRate;
  String category;
  String description;
  String account;
  String transactionkind;
  String payRythm;
  int? id;

  FixedTransaction({required this.startDate, required this.yearlyRate, required this.category, required this.description, required this.account, required this.transactionkind, required this.payRythm, this.id});

  FixedTransaction copyWith({
    DateTime? startDate,
    double? yearlyRate,
    String? category,
    String? description,
    String? account,
    String? transactionkind,
    String? payRythm,
    int? id,
  }){
    return FixedTransaction(
      startDate: startDate ?? this.startDate,
      yearlyRate: yearlyRate ?? this.yearlyRate,
      category: category ?? this.category,
      description: description ?? this.description,
      account: account ?? this.account,
      transactionkind: transactionkind ?? this.transactionkind,
      payRythm: payRythm ?? this.payRythm,
      id: id ?? id
    );
  }

  factory FixedTransaction.fromMap(Map<String, dynamic> map){
    return FixedTransaction(
      startDate: DateTime.parse(map['start_date']),
      yearlyRate: double.parse(map['yearly_rate']),
      category: map['category'],
      description: map['description'],
      account: map['account'],
      transactionkind: map['transactionkind'],
      payRythm: map['pay_rythm'],
      id: map['id'],
    );
  }

  factory FixedTransaction.fromOfflineMap(Map<String, dynamic> map){
    return FixedTransaction(
      startDate: DateTime.parse(map['start_date']),
      yearlyRate: map['yearly_rate'],
      category: map['category'],
      description: map['description'],
      account: map['account'],
      transactionkind: map['transactionkind'],
      payRythm: map['pay_rythm'],
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start_date': DateFormat('yyyy-MM-dd').format(startDate),
      'yearly_rate': yearlyRate.toString(),
      'category': category,
      'description': description,
      'account': account,
      'transactionkind': transactionkind,
      'pay_rythm': payRythm,
    };
  }

  String toJson() => json.encode(toMap());

  factory FixedTransaction.fromJson(String source) =>
    FixedTransaction.fromMap(json.decode(json.decode(source)));

}