import 'dart:convert';

class Update {
  final int? id;
  String tableName;
  String status;
  String data;

  Update({required this.tableName, required this.status, required this.data, this.id});

  Update copyWith({
    String? tableName,
    String? status,
    String? data,
    int? id,
  }){
    return Update(
      tableName: tableName ?? this.tableName,
      status: status ?? this.status,
      data: data ?? this.data,
      id: id ?? this.id,
    );
  }

  factory Update.fromMap(Map<String, dynamic> map){
    return Update(
      tableName: map['table_name'],
      status: map['status'],
      data: map['data'],
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'table_name': tableName,
      'status': status,
      'data': data,
    };
  }

  String toJson() => json.encode(toMap());

  factory Update.accountFromJson(String source) =>
  Update.fromMap(json.decode(source));

}