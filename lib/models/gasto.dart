class Gasto {
  final int id;
  final String description;
  final double amount;
  final String category;
  final String expenseType;
  final String date;

  const Gasto({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseType,
    required this.date,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'] as int,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String? ?? 'Otros',
      expenseType: json['expense_type'] as String? ?? 'personal_variable',
      date: json['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'expense_type': expenseType,
      'date': date,
    };
  }

  @override
  String toString() =>
      'Gasto(id: $id, description: $description, amount: $amount, category: $category)';
}

class HistorialResponse {
  final List<Gasto> gastos;
  final int total;
  final int page;
  final int totalPages;
  final double resumenTotal;

  const HistorialResponse({
    required this.gastos,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.resumenTotal,
  });

  factory HistorialResponse.fromJson(Map<String, dynamic> json) {
    final resumen = json['resumen'] as Map<String, dynamic>?;
    final resumenTotal = resumen != null
        ? (resumen['total'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return HistorialResponse(
      gastos: (json['gastos'] as List<dynamic>)
          .map((e) => Gasto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
      resumenTotal: resumenTotal,
    );
  }
}
