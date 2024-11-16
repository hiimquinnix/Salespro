import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stocks;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stocks,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: double.parse(data['price'] ?? '0'),
      category: data['category'] ?? '',
      stocks: int.parse(data['stocks'] ?? '0'),
    );
  }
}