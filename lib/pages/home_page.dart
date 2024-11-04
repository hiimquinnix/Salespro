// ignore_for_file: prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salespro/auth/auth_page.dart';
import 'package:salespro/pages/forecasting_page.dart';
import 'package:salespro/pages/checkout_page.dart'; // Import your checkout page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;

  List<String> categories = ['All']; // Initial default category
  String selectedCategory = 'All'; // Default selected category

  // Store selected items to show in the checkout
  Map<String, int> selectedItems = {}; // Track selected items and quantities

  // Function to update categories from CategoryPage
  void updateCategories(List<String> newCategories) {
    setState(() {
      categories = ['All', ...newCategories]; // 'All' is always default
      if (!categories.contains(selectedCategory)) {
        selectedCategory = 'All';
      }
    });
  }

  // Add items and quantities to selectedItems map
  void addItemToCheckout(String itemName, int quantity) {
    setState(() {
      selectedItems[itemName] = quantity;
    });
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
  onPressed: () {
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
  },
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
                    'lib/images/logo.png', // this is the logo path
                    width: 120, // the size of the logo
                    height: 100,
                  ),
                  SizedBox(height: 10), // Space between logo and text
                  Text(
                    'Signed in as: ' + user.email!,
                    style: TextStyle(
                      fontSize: 9, // Adjust text size if necessary
                      color: Colors.black, // Adjust text color if necessary
                    ),
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
                      backgroundColor: Colors.green, // Button color
                      padding: EdgeInsets.symmetric(vertical: 16.0), // Button height
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
                      style: TextStyle(
                        fontSize: 18.0, // Larger text
                        color: Colors.white, // White text color
                      ),
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
                    decoration: InputDecoration(
                      hintText: "Search...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(),
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
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                padding: EdgeInsets.all(8.0),
                children: [
                  POSItem(
                    itemName: "Bibimbap",
                    price: 180,
                    onItemSelect: addItemToCheckout,
                  ),
                  POSItem(
                    itemName: "Kimchi",
                    price: 120,
                    onItemSelect: addItemToCheckout,
                  ),
                  POSItem(
                    itemName: "Tteokbokki",
                    price: 150,
                    onItemSelect: addItemToCheckout,
                  ),
                  POSItem(
                    itemName: "Samgyeopsal",
                    price: 300,
                    onItemSelect: addItemToCheckout,
                  ),
                  POSItem(
                    itemName: "Jajangmyeon",
                    price: 200,
                    onItemSelect: addItemToCheckout,
                  ),
                  POSItem(
                    itemName: "Bulgogi",
                    price: 250,
                    onItemSelect: addItemToCheckout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Create a POSItem widget with quantity tracking functionality
class POSItem extends StatefulWidget {
  final String itemName;
  final double price;
  final void Function(String itemName, int quantity) onItemSelect;

  const POSItem({
    Key? key,
    required this.itemName,
    required this.price,
    required this.onItemSelect,
  }) : super(key: key);

  @override
  State<POSItem> createState() => _POSItemState();
}

class _POSItemState extends State<POSItem> {
  int quantity = 0;

  void incrementQuantity() {
    setState(() {
      quantity++;
    });
    widget.onItemSelect(widget.itemName, quantity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: incrementQuantity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fastfood, size: 50, color: Colors.green),
                SizedBox(height: 8),
                Text(widget.itemName, style: TextStyle(fontSize: 16)),
                SizedBox(height: 4),
                Text("₱${widget.price.toStringAsFixed(0)}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
          if (quantity > 0)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.green,
                radius: 12,
                child: Text(
                  quantity.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),  
        ],
      ),
    );
  }
}
