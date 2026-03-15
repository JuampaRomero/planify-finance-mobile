class CategoryData {
  final String name;
  final double value;

  const CategoryData({
    required this.name,
    required this.value,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  @override
  String toString() => 'CategoryData(name: $name, value: $value)';
}

class Movimiento {
  final String description;
  final String category;
  final String date;
  final double amount;

  const Movimiento({
    required this.description,
    required this.category,
    required this.date,
    required this.amount,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      description: json['description'] as String,
      category: json['category'] as String,
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'category': category,
      'date': date,
      'amount': amount,
    };
  }

  @override
  String toString() =>
      'Movimiento(description: $description, category: $category, date: $date, amount: $amount)';
}

class DashboardData {
  final double salary;
  final List<CategoryData> categories;
  final List<Movimiento> movimientos;
  final double fixedExpenses;
  final double creditCard;

  const DashboardData({
    required this.salary,
    required this.categories,
    required this.movimientos,
    required this.fixedExpenses,
    required this.creditCard,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      salary: (json['salary'] as num).toDouble(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => CategoryData.fromJson(e as Map<String, dynamic>))
          .toList(),
      movimientos: (json['movimientos'] as List<dynamic>)
          .map((e) => Movimiento.fromJson(e as Map<String, dynamic>))
          .toList(),
      fixedExpenses: (json['fixedExpenses'] as num).toDouble(),
      creditCard: (json['creditCard'] as num).toDouble(),
    );
  }

  // Computed getters
  double get variableExpenses => categories.fold(0.0, (sum, c) => sum + c.value);
  double get totalSpent => fixedExpenses + creditCard + variableExpenses;
  double get margin => salary - totalSpent;
  double get marginPercentage =>
      salary > 0 ? (margin / salary * 100).clamp(0.0, 100.0) : 0.0;

  @override
  String toString() =>
      'DashboardData(salary: $salary, totalSpent: $totalSpent, margin: $margin)';
}
