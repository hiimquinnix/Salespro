import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, int> selectedItems;
  final Function(String) onItemRemoved; // Callback function

  CheckoutPage({required this.selectedItems, required this.onItemRemoved});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  double totalPrice = 0;

  // Define item prices
  final Map<String, double> itemPrices = {
    'Bibimbap': 180,
    'Kimchi': 120,
    'Tteokbokki': 150,
    'Samgyeopsal': 300,
    'Jajangmyeon': 200,
    'Bulgogi': 250,
  };

  // Update the total price whenever an item is added or removed
  void updateTotalPrice() {
    totalPrice = 0;
    widget.selectedItems.forEach((item, quantity) {
      double? price = itemPrices[item];
      if (price != null) {
        totalPrice += price * quantity;
      }
    });
  }

  // Method to decrease the quantity of an item
  void decrementItem(String itemName) {
    setState(() {
      if (widget.selectedItems[itemName]! > 1) {
        widget.selectedItems[itemName] = widget.selectedItems[itemName]! - 1;
      } else {
        widget.selectedItems.remove(itemName);
        widget.onItemRemoved(itemName); // Notify HomePage to remove the item
      }
      updateTotalPrice();
    });
  }

  @override
  void initState() {
    super.initState();
    updateTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Receipt",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Divider(),
            Expanded(
              child: ListView(
                children: widget.selectedItems.entries.map((entry) {
                  String itemName = entry.key;
                  int quantity = entry.value;
                  double? price = itemPrices[itemName];
                  double itemTotal = (price ?? 0) * quantity;

                  return ListTile(
                    title: Text(itemName),
                    subtitle: Text("₱${price?.toStringAsFixed(2)} x $quantity"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => decrementItem(itemName),
                        ),
                        Text("₱${itemTotal.toStringAsFixed(2)}"),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            Divider(),
            ListTile(
              title: Text(
                "Total",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                "₱${totalPrice.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
