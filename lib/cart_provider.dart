import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({required this.name, required this.price, required this.quantity});
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(String name, double price) {
    if (_items.containsKey(name)) {
      _items.update(
        name,
        (existingItem) => CartItem(
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        name,
        () => CartItem(name: name, price: price, quantity: 1),
      );
    }
    notifyListeners();
  }

  void removeItem(String name) {
    _items.remove(name);
    notifyListeners();
  }

  void decrementItem(String name) {
    if (!_items.containsKey(name)) return;
    if (_items[name]!.quantity > 1) {
      _items.update(
        name,
        (existingItem) => CartItem(
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity - 1,
        ),
      );
    } else {
      _items.remove(name);
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }

  Future<void> updateFirebaseStock() async {
    try {
      for (var item in _items.entries) {
        final itemRef = FirebaseFirestore.instance.collection('Items').where('name', isEqualTo: item.key);
        final querySnapshot = await itemRef.get();
        if (querySnapshot.docs.isNotEmpty) {
          final docId = querySnapshot.docs.first.id;
          final currentStock = int.parse(querySnapshot.docs.first.data()['stocks'].toString());
          final newStock = currentStock - item.value.quantity;
          await FirebaseFirestore.instance.collection('Items').doc(docId).update({
            'stocks': newStock.toString()
          });
        }
      }
    } catch (e) {
      print('Error updating stock: $e');
    }
  }
}