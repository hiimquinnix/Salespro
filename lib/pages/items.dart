import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All items',
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
  const Items(
      {Key? key,
      required void Function(List<String> newCategories) updateCategories})
      : super(key: key);

  @override
  _ItemsState createState() => _ItemsState();
}

class _ItemsState extends State<Items> {
  final List<Map<String, dynamic>> _items = [];
  final List<String> _categories = [
    'Noodles',
    'Drinking Beverage',
    'Ice Creams'
  ]; // Predefined categories
  String _selectedCategory = 'All';

  void _addItem(
      String name, String description, double price, String category) {
    setState(() {
      _items.add({
        'name': name,
        'description': description,
        'price': price,
        'category': category
      });
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _confirmDelete(BuildContext context, int index, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel action
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteItem(index); // Confirm deletion
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
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredItems = _selectedCategory == 'All'
        ? _items
        : _items
            .where((item) => item['category'] == _selectedCategory)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('All Items'),
        actions: [
          // Category filter dropdown in the AppBar
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
      body: _items.isEmpty
          ? Center(
              child: Text(
                'No items available. Add new items!',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Dismissible(
                  key: UniqueKey(),
                  direction:
                      DismissDirection.endToStart, // Swipe from right to left
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    // Return false to prevent automatic dismissal; show confirmation dialog instead
                    _confirmDelete(context, index, item['name'] as String);
                    return false; // Prevent immediate dismissal
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    child: ListTile(
                      leading:
                          Icon(Icons.fastfood, size: 40, color: Colors.green),
                      title: Text(
                        item['name'] as String,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['description'] as String,
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            "Category: ${item['category']}",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '₱${item['price'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open a dialog to add a new item
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
  String _selectedCategory = 'Noodles'; // Default category

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
              widget.onAddItem(
                  name, description, price, _selectedCategory); // Pass category
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
