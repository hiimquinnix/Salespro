import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String name;
  String description;
  String stocks;
  String price;
  String category;

  // Constructor
  Product({
    required this.name,
    required this.description,
    required this.stocks,
    required this.price,
    required this.category,
  });

  // Create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      stocks: data['stocks'] ?? '',
      price: data['price'] ?? '',
      category: data['category'] ?? '',
    );
  }

  // Convert Product to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'stocks': stocks,
      'price': price,
      'category': category,
    };
  }

  
}
