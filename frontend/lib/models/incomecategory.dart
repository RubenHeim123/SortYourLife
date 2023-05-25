import 'dart:convert';

class IncomeCategory {
  String incomeCategoryName;
  int? id;

  IncomeCategory({required this.incomeCategoryName, this.id});

  IncomeCategory copyWith({
    String? incomeCategoryName,
    int? id,
  }){
    return IncomeCategory(
      incomeCategoryName: incomeCategoryName ?? this.incomeCategoryName,
      id: id ?? this.id,
    );
  }

  factory IncomeCategory.fromMap(Map<String, dynamic> map){
    return IncomeCategory(
      incomeCategoryName: map['income_category_name'],
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'income_category_name': incomeCategoryName,
    };
  }

  String toJson() => json.encode(toMap());

  factory IncomeCategory.fromJson(String source) =>
  IncomeCategory.fromMap(json.decode(json.decode(source)));

}