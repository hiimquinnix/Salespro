import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:salespro/auth/auth_page.dart';
import 'package:salespro/pages/forecasting_page.dart';
import 'package:salespro/pages/checkout_page.dart'; // Make sure to import CheckoutPage

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  List<String> categories = []; // List to hold categories from Firestore
  String selectedCategory = 'All';
  String _searchQuery = ''; // Add search query state
  final TextEditingController _searchController = TextEditingController();

  Map<String, int> selectedItems = {}; // Holds selected items and their quantities
  Map<String, int> stockQuantities = {}; // Real-time stock quantities

  // Fetch stock quantities in real-time
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
    _fetchStockQuantities(); // Fetch initial stock quantities
    _fetchCategories(); // Fetch categories from Firestore
    _searchController.addListener(_onSearchChanged); // Listen for search input changes
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose of the controller when done
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _fetchCategories() async {
    // Fetch categories from Firestore collection
    final snapshot = await FirebaseFirestore.instance.collection('Categories').get();
    setState(() {
      categories = ['All'] + snapshot.docs.map((doc) => doc['name'].toString()).toList();
    });
  }

  void addItemToCheckout(String itemName, int quantity) {
    setState(() {
      if (quantity > 0 && quantity <= (stockQuantities[itemName] ?? 0)) {
        selectedItems[itemName] = quantity; // Add or update the quantity when confirmed
      } else {
        selectedItems.remove(itemName); // Remove item if quantity is 0 or exceeds stock
      }
    });
  }

  void navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          selectedItems: selectedItems,
          onItemRemoved: (itemName) {
            setState(() {
              selectedItems.remove(itemName);
            });
          },
        ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: Text("SalesPRO"),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: navigateToCheckout,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
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
                    style: TextStyle(fontSize: 9, color: Colors.black),
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
            ListTile(
              leading: Icon(Icons.logout),
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
      body: Container(
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: [
            Row(
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
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  flex: 1,
                  child: categories.isEmpty
                      ? CircularProgressIndicator()
                      : DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          items: categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCategory = newValue!;
                            });
                          },
                        ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchPOSItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No items available.'));
                  }

                  // Filter items based on category and search query
                  final posItems = snapshot.data!.where((item) {
                    final itemCategory = item['category'].toString();
                    final itemName = item['name'].toLowerCase();
                    final searchQuery = _searchQuery.toLowerCase();
                    return (selectedCategory == 'All' || itemCategory == selectedCategory) &&
                        itemName.contains(searchQuery);
                  }).toList();

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemCount: posItems.length,
                    itemBuilder: (context, index) {
                      final item = posItems[index];
                      final itemName = item['name'];
                      final stock = stockQuantities[itemName] ?? 0;
                      return POSItem(
                        itemName: itemName,
                        price: item['price'],
                        stock: stock,
                        onItemSelect: addItemToCheckout,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class POSItem extends StatefulWidget {
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
  _POSItemState createState() => _POSItemState();
}

class _POSItemState extends State<POSItem> {
  int quantity = 0;

  void _incrementQuantity() {
    if (quantity < widget.stock) {
      setState(() {
        quantity++;
      });
      widget.onItemSelect(widget.itemName, quantity);
    }
  }

  void _decrementQuantity() {
    if (quantity > 0) {
      setState(() {
        quantity--;
      });
      widget.onItemSelect(widget.itemName, quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.itemName, style: TextStyle(fontSize: 16.0)),
          Text('₱${widget.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 14.0)),
          Text('Stock: ${widget.stock}', style: TextStyle(fontSize: 12.0, color: Colors.redAccent)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: _decrementQuantity,
                color: quantity > 0 ? Colors.black : Colors.grey,
              ),
              Text('$quantity', style: TextStyle(fontSize: 18.0)),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: _incrementQuantity,
                color: quantity < widget.stock ? Colors.black : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
