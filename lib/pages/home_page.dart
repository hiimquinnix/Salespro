import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salespro/cart_provider.dart';
import 'checkout_page.dart';
import 'forecasting_page.dart';
import 'auth/auth_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<String> categories = [];
  String selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, int> stockQuantities = {};

  void _fetchStockQuantities() {
    FirebaseFirestore.instance.collection('Items').snapshots().listen((snapshot) {
      final Map<String, int> newStockQuantities = {};
      for (var doc in snapshot.docs) {
        final itemName = doc['name'];
        final stock = int.tryParse(doc['stocks'].toString()) ?? 0;
        newStockQuantities[itemName] = stock;
      }
      setState(() {
        stockQuantities = newStockQuantities;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchStockQuantities();
    _fetchCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('Categories').get();
    setState(() {
      categories = ['All'] + snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPOSItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Items').get();
      return snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'price': _convertToDouble(doc['price']),
          'category': doc['category'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching POS items: $e");
      return [];
    }
  }

  double _convertToDouble(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "SalesPRO",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CheckoutPage()),
                  );
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  Image.asset(
                    'lib/images/logo.png',
                    width: 120,
                    height: 100,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Signed in as: ' + user.email!,
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text("SALES"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/salespage');
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text("RECEIPTS"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/receiptpage');
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text("INVENTORY"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/itemspage');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Sign Out"),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Confirm Logout'),
                      content: Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => AuthPage(),
                              ),
                              (route) => false,
                            );
                          },
                          child: Text('Confirm'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForecastPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Forecasting",
                      style: TextStyle(fontSize: 18.0, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Card(
            elevation: 4,
            margin: EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                    items: categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPOSItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No items available."));
                }
                final filteredItems = snapshot.data!.where((item) {
                  final matchesCategory =
                      selectedCategory == 'All' || item['category'] == selectedCategory;
                  final matchesSearch = item['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                }).toList();

                return GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return POSItem(
                      itemName: item['name'],
                      price: item['price'],
                      stock: stockQuantities[item['name']] ?? 0,
                      onItemSelect: (itemName, quantity) {
                        if (quantity > 0) {
                          cart.addItem(itemName, item['price']);
                        } else {
                          cart.removeItem(itemName);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class POSItem extends StatelessWidget {
  final String itemName;
  final double price;
  final int stock;
  final Function(String, int) onItemSelect;

  POSItem({
    required this.itemName,
    required this.price,
    required this.stock,
    required this.onItemSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.items[itemName]?.quantity ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(itemName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text('₱${price.toStringAsFixed(2)}'),
            Text(
              stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
              style: TextStyle(
                color: stock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, color: Colors.red),
                  onPressed: quantity > 0 ? () => onItemSelect(itemName, quantity - 1) : null,
                ),
                Text('$quantity'),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.green),
                  onPressed: stock > quantity
                      ? () => onItemSelect(itemName, quantity + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}