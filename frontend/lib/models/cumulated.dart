import 'dart:convert';

class CumulatedIncomeCategory {
  String incomeCategoryName;
  int owner;
  int? id;

  CumulatedIncomeCategory({required this.incomeCategoryName, required this.owner, this.id});

  CumulatedIncomeCategory copyWith({
    String? incomeCategoryName,
    int? owner,
    int? id,
  }){
    return CumulatedIncomeCategory(
      incomeCategoryName: incomeCategoryName ?? this.incomeCategoryName,
      owner: owner ?? this.owner,
      id: id ?? this.id,
    );
  }

  factory CumulatedIncomeCategory.fromMap(Map<String, dynamic> map){
    return CumulatedIncomeCategory(
      incomeCategoryName: map['income_category_name'],
      owner: map['owner'],
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'income_category_name': incomeCategoryName,
      'owner': owner,
    };
  }

  String toJson() => json.encode(toMap());

  factory CumulatedIncomeCategory.fromJson(String source) =>
  CumulatedIncomeCategory.fromMap(json.decode(source));

}