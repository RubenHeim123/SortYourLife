import 'dart:convert';

class Account {
  final int? id;
  String accountName;
  String accountAmount;

  Account({required this.accountName, required this.accountAmount, this.id});

  Account copyWith({
    String? accountName,
    String? accountAmount,
    int? id,
  }){
    return Account(
      accountName: accountName ?? this.accountName,
      accountAmount: accountAmount ?? this.accountAmount,
      id: id ?? this.id,
    );
  }

  factory Account.fromMap(Map<String, dynamic> map){
    return Account(
      accountName: map['account_name'],
      accountAmount: map['account_amount'],
      id: map['id'],
    );
  }

  factory Account.fromOfflineMap(Map<String, dynamic> map){
    return Account(
      accountName: map['account_name'],
      accountAmount: map['account_amount'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account_name': accountName,
      'account_amount': accountAmount,
    };
  }

  String toJson() => json.encode(toMap());

  factory Account.fromJson(String source) =>
  Account.fromOfflineMap(json.decode(json.decode(source)));

}