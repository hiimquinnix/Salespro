import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/model/product_model.dart';

import '../utils/image_picker.dart';

class Items extends StatefulWidget {
  const Items({super.key, required this.updateCategories});

  final Function(List<String> newCategories) updateCategories;

  @override
  ItemsState createState() => ItemsState();

}

class ItemsState extends State<Items> {

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _categories = [
    'Noodles',
    'Drinking Beverage',
    'Ice Creams'
  ];
  String _selectedCategory = 'All';

  Future<void> _addItem(String name, String description, double price,
      String category, int stocks, File? file) async {

    final imageRef = _storage.ref('items').child(name);
    String imageUrl = "";
    CollectionReference itemsRef = _firestore.collection('Items');
    
    try {
      await imageRef.putFile(File(file?.path ?? ""));
      imageUrl = await imageRef.getDownloadURL();

      await itemsRef.add({
        'name': name,
        'description': description,
        'category': category,
        'price': price.toString(),
        'stocks': stocks.toString(),
        'image_url': imageUrl
      });
    } catch (e) {
      log("Error $e");
    }
  }

  Future<void> _updateItem(String itemId, String name, String description,
      double price, String category, int stocks, File? file) async {

    final imageRef = _storage.ref('items').child(name);
    String imageUrl = "";
    try {
      await imageRef.putFile(File(file?.path ?? ""));
      imageUrl = await imageRef.getDownloadURL();

      await _firestore.collection('Items').doc(itemId).update({
        'name': name,
        'description': description,
        'category': category,
        'price': price.toString(),
        'stocks': stocks.toString(),
        'image_url': imageUrl,
      });
    } catch (e) {
      log("Error $e");
    }
  }

  Future<void> _deleteItem(String itemId) async {
    await _firestore.collection('Items').doc(itemId).delete();
  }

  void _confirmDelete(BuildContext context, String itemId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteItem(itemId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$itemName deleted"),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Stream<List<Product>> fetchItems() {
    return _firestore.collection('Items').snapshots().map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    });
  }

  void _editItem(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        product: product,
        onEditItem: _updateItem,
        categories: _categories,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Items'),
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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text("An error occurred!"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products available"));
          } else {
            List<Product> items = snapshot.data!;
            List<Product> filteredItems = _selectedCategory == 'All'
                ? items
                : items
                    .where((item) => item.category == _selectedCategory)
                    .toList();

            return ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final product = filteredItems[index];
                return Dismissible(
                  key: Key(product.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm"),
                          content: const Text("Are you sure you want to delete this item?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("CANCEL"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("DELETE"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _deleteItem(product.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${product.name} deleted")),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.fill,
                              height: 50,
                              width: 40,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stocks: ${product.stocks}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: ${product.category}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Text(
                              '₱${product.price}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed: () => _editItem(context, product),
                            ),
                          ],
                        ),
                      ],
                    ),
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddItemDialog extends StatefulWidget {
  final Function(String, String, double, String, int, File?) onAddItem;
  final List<String> categories;

  const AddItemDialog({
    super.key,
    required this.onAddItem,
    required this.categories,
  });

  @override
  AddItemDialogState createState() => AddItemDialogState();
}

class AddItemDialogState extends State<AddItemDialog> {

  ImagePickerUtil? imagePickerUtil;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stocksController = TextEditingController();
  String _selectedCategory = 'Noodles';

  File? imageFile;
  String fileName = "";

  void setImageFile(File? file) {
    setState(() {
      imageFile = file;
      fileName = path.basename(file?.path ?? "");
    });
  }

  void pickImage() async {

    var file = await ImagePickerUtil.pickImage();

    setImageFile(await Isolate.run(() => file));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Item'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _stocksController,
              decoration: const InputDecoration(labelText: 'Stocks'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (₱)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
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
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 10),
            const Text(
              "Description",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.0,
                fontWeight: FontWeight.w500
              )
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                pickImage();
                log("aasdasd");
              },
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.green)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      fileName.isEmpty
                      ? "Upload image"
                      : fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text;
            final description = _descriptionController.text;
            final price = double.tryParse(_priceController.text) ?? 0.0;
            final stocks = int.tryParse(_stocksController.text) ?? 0;
            
            if (name.isNotEmpty &&
                description.isNotEmpty &&
                price > 0 &&
                _selectedCategory.isNotEmpty &&
                stocks >= 0 && fileName.isNotEmpty) {
              widget.onAddItem(name, description, price, _selectedCategory, stocks, imageFile);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class EditItemDialog extends StatefulWidget {
  final Product product;
  final Function(String, String, String, double, String, int, File?) onEditItem;
  final List<String> categories;

  const EditItemDialog({
    super.key,
    required this.product,
    required this.onEditItem,
    required this.categories,
  });

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {

  ImagePickerUtil? imagePickerUtil;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stocksController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stocksController = TextEditingController(text: widget.product.stocks.toString());
    _selectedCategory = widget.product.category;
  }

  File? imageFile;
  String fileName = "";

  void setImageFile(File? file) {
    setState(() {
      imageFile = file;
      fileName = path.basename(file?.path ?? "");
    });
  }

  void pickImage() async {

    var file = await ImagePickerUtil.pickImage();

    setImageFile(await Isolate.run(() => file));

    log("imagefilecall ${imageFile?.path}");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500
                )
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500
                )
              ),
            ),
            TextField(
              controller: _stocksController,
              decoration: const InputDecoration(
                labelText: 'Stocks',
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500
                )
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₱)',
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500
                )
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
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
              decoration: const InputDecoration(labelText: 'Category'),

            ),
            const SizedBox(height: 10),
            const Text(
              "Description",
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.0,
                fontWeight: FontWeight.w500
              )
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                pickImage();
                log("aasdasd");
              },
              child: Container(
                height: 50,
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: Colors.green)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      fileName.isEmpty
                      ? "Upload image"
                      : fileName,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameController.text;
            final description = _descriptionController.text;
            final price = double.tryParse(_priceController.text) ?? 0.0;
            final stocks = int.tryParse(_stocksController.text) ?? 0;

            if (name.isNotEmpty &&
                description.isNotEmpty &&
                price > 0 &&
                _selectedCategory.isNotEmpty &&
                stocks >= 0) {
              widget.onEditItem(widget.product.id, name, description, price, _selectedCategory, stocks, imageFile);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}