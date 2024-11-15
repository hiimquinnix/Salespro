import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'receipts_page.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, int> selectedItems;
  final Function(String) onItemRemoved;

  CheckoutPage({required this.selectedItems, required this.onItemRemoved});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  double totalPrice = 0;
  Map<String, double> itemPrices = {};
  final TextEditingController _receivedAmountController = TextEditingController();
  List<Map<String, dynamic>> receipts = [];

  @override
  void dispose() {
    _receivedAmountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    updateTotalPrice();
    fetchProductData();
  }

  Future<void> fetchProductData() async {
    for (var itemName in widget.selectedItems.keys) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Items')
            .where('name', isEqualTo: itemName)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = querySnapshot.docs.first;
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          double price = double.tryParse(data['price'] ?? '0.0') ?? 0.0;

          setState(() {
            itemPrices[itemName] = price;
          });
        } else {
          setState(() {
            itemPrices[itemName] = 0.0;
          });
        }
      } catch (e) {
        setState(() {
          itemPrices[itemName] = 0.0;
        });
      }
    }
  }

  void updateTotalPrice() {
    setState(() {
      totalPrice = 0;
      widget.selectedItems.forEach((item, quantity) {
        double? price = itemPrices[item];
        if (price != null) {
          totalPrice += price * quantity;
        }
      });
    });
  }

  // Increment the quantity of an item
  void incrementItem(String itemName) {
    setState(() {
      widget.selectedItems[itemName] = (widget.selectedItems[itemName] ?? 0) + 1;
      updateTotalPrice();
    });
  }

  // Decrement the quantity of an item
  void decrementItem(String itemName) {
    setState(() {
      if (widget.selectedItems[itemName]! > 1) {
        widget.selectedItems[itemName] = widget.selectedItems[itemName]! - 1;
      } else {
        widget.selectedItems.remove(itemName);
      }
      updateTotalPrice();
    });
  }

  // Remove an item completely from the cart
  void removeItem(String itemName) {
    setState(() {
      widget.selectedItems.remove(itemName);
      updateTotalPrice();
    });
    widget.onItemRemoved(itemName);
  }

  void showPaymentSummaryDialog(double receivedAmount) {
    double balance = receivedAmount - totalPrice;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Summary"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(),
              ...widget.selectedItems.entries.map((entry) {
                String itemName = entry.key;
                int quantity = entry.value;
                double? price = itemPrices[itemName];
                double itemTotal = (price ?? 0) * quantity;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(itemName),
                      Text("x $quantity  ₱${itemTotal.toStringAsFixed(2)}"),
                    ],
                  ),
                );
              }).toList(),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Amount Due", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₱${totalPrice.toStringAsFixed(2)}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Amount Received"),
                  Text("₱${receivedAmount.toStringAsFixed(2)}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Change", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text("₱${balance.toStringAsFixed(2)}"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                // Add receipt to the list of receipts
                receipts.add({
                  'referenceNumber': DateTime.now().millisecondsSinceEpoch.toString(),
                  'date': DateTime.now(),
                  'time': DateFormat('HH:mm').format(DateTime.now()),
                  'dayOfWeek': DateFormat('EEEE').format(DateTime.now()),
                  'totalAmount': totalPrice,
                  'receivedAmount': receivedAmount,
                  'balance': balance,
                  'items': Map<String, int>.from(widget.selectedItems),
                });

                setState(() {
                  widget.selectedItems.clear();
                  totalPrice = 0;
                });
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void showReceivedAmountDialog() {
    _receivedAmountController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Received Amount"),
          content: TextField(
            controller: _receivedAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "₱0.00"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                double receivedAmount = double.tryParse(_receivedAmountController.text) ?? 0;
                if (receivedAmount < totalPrice) {
                  // Show a warning if the received amount is less than the total price
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Received amount is less than total price')),
                  );
                } else {
                  Navigator.of(context).pop();
                  showPaymentSummaryDialog(receivedAmount);
                }
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptsPage(receipts: receipts),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selected Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: widget.selectedItems.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  String itemName = widget.selectedItems.keys.elementAt(index);
                  int quantity = widget.selectedItems[itemName] ?? 0;
                  double price = itemPrices[itemName] ?? 0.0;
                  double itemTotal = price * quantity;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$itemName x$quantity"),
                      Text("₱${itemTotal.toStringAsFixed(2)}"),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => decrementItem(itemName),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => incrementItem(itemName),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              removeItem(itemName); // Remove item from cart
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Price", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("₱${totalPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: showReceivedAmountDialog,
              child: Text("Proceed to Payment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}