import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/model/product_model.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All Items',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Items(
        updateCategories: (List<String> newCategories) {},
      ),
    );
  }
}

class Items extends StatefulWidget {
  const Items({Key? key, required this.updateCategories}) : super(key: key);

  final Function(List<String> newCategories) updateCategories;

  @override
  _ItemsState createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _categories = ['Noodles', 'Drinking Beverage', 'Ice Creams'];
  String _selectedCategory = 'All';

  Future<void> _addItem(
      String name, String description, double price, String category) async {
    CollectionReference itemsRef = _firestore.collection('Items');
    await itemsRef.add({
      'name': name,
      'description': description,
      'category': category,
      'price': price.toString(),
      'stocks': '100' // Default stocks value
    });
  }

  Future<void> _deleteItem(String itemId) async {
    await _firestore.collection('Items').doc(itemId).delete();
  }

  void _confirmDelete(BuildContext context, String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteItem(itemId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$itemName deleted"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Stream<List<Product>> fetchItems() {
    return _firestore.collection('Items').snapshots().map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('All Items'),
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (newCategory) {
              setState(() {
                _selectedCategory = newCategory!;
              });
            },
            items: ['All', ..._categories]
                .map((category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: fetchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("An error occurred!"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No products available"));
          } else {
            List<Product> items = snapshot.data!;
            List<Product> filteredItems = _selectedCategory == 'All'
                ? items
                : items.where((item) => item.category == _selectedCategory).toList();

            return ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final product = filteredItems[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 3), // Shadow position
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          color: Colors.green.shade700,
                          size: 40,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              product.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Stocks: ${product.stocks}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Category: ${product.category}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        '₱${product.price}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                AddItemDialog(onAddItem: _addItem, categories: _categories),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddItemDialog extends StatefulWidget {
  final Function(String, String, double, String) onAddItem;
  final List<String> categories;

  const AddItemDialog(
      {Key? key, required this.onAddItem, required this.categories})
      : super(key: key);

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Noodles';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: 'Description'),
          ),
          TextField(
            controller: _priceController,
            decoration: InputDecoration(labelText: 'Price (₱)'),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            onChanged: (newCategory) {
              setState(() {
                _selectedCategory = newCategory!;
              });
            },
            items: widget.categories
                .map((category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            decoration: InputDecoration(labelText: 'Category'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text;
            final description = _descriptionController.text;
            final price = double.tryParse(_priceController.text) ?? 0.0;
            if (name.isNotEmpty &&
                description.isNotEmpty &&
                price > 0 &&
                _selectedCategory.isNotEmpty) {
              widget.onAddItem(name, description, price, _selectedCategory);
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
