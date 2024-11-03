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
  List<String> selectedItems = [];

  // Function to update categories from CategoryPage
  void updateCategories(List<String> newCategories) {
    setState(() {
      categories = ['All', ...newCategories]; // 'All' is always default
      if (!categories.contains(selectedCategory)) {
        selectedCategory = 'All';
      }
    });
  }

  // Function to add items to the selectedItems list
  void addItemToCheckout(String item) {
    setState(() {
      selectedItems.add(item); // Add item to checkout list
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

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
                MaterialPageRoute(builder: (context) => CheckoutPage()),
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
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity, // Full width button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Button color
                  padding: EdgeInsets.symmetric(vertical: 26.0), // Button height
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular button
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalesForecastPage(),
                    ),
                  );
                },
                child: Text(
                  "Forecasting",
                  style: TextStyle(
                    fontSize: 24.0, // Larger text
                    color: Colors.white, // White text color
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                // Search bar
                Expanded(
                  flex: 2, // Give the search bar more space
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
                SizedBox(width: 16.0), // Space between search bar and dropdown
                // Dropdown for category selection
                Expanded(
                  flex: 1, // Give dropdown less space
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory, // Current selected value
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
            SizedBox(height: 15),
            Divider(
              thickness: 0.4,
              color: Colors.grey.shade800,
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}
