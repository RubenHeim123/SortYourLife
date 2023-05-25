import 'dart:convert';

class OutgoingCategory {
  String outgoingCategoryName;
  String budget;
  int? id;
  String? expenses;
  String? sum;

  OutgoingCategory({required this.outgoingCategoryName, required this.budget, this.id, this.expenses, this.sum});

  OutgoingCategory copyWith({
    String? outgoingCategoryName,
    String? budget,
    int? id,
    String? expenses,
    String? sum,
  }){
    return OutgoingCategory(
      outgoingCategoryName: outgoingCategoryName ?? this.outgoingCategoryName,
      budget: budget ?? this.budget,
      id: id ?? this.id,
      expenses: expenses ?? this.expenses,
      sum: sum ?? this.sum,
    );
  }

  factory OutgoingCategory.fromMap(Map<String, dynamic> map){
    return OutgoingCategory(
      outgoingCategoryName: map['outgoing_category_name'],
      budget: map['budget'],
      id: map['id'],
      expenses: map['expenses'],
      sum: map['sum'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'outgoing_category_name': outgoingCategoryName,
      'budget': budget,
    };
  }

  Map<String, dynamic> toOfflineMap() {
    return {
      'outgoing_category_name': outgoingCategoryName,
      'budget': budget,
      'expenses': expenses,
      'sum': sum,
    };
  }

  String toJson() => json.encode(toMap());

  factory OutgoingCategory.fromJson(String source) =>
  OutgoingCategory.fromMap(json.decode(json.decode(source)));

}