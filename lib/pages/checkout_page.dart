import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:salespro/cart_provider.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

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
            Text("Selected Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: cart.items.length,
                separatorBuilder: (context, index) => Divider(),
                itemBuilder: (context, index) {
                  final item = cart.items.values.elementAt(index);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item.name} x${item.quantity}"),
                      Text("₱${(item.price * item.quantity).toStringAsFixed(2)}"),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () => cart.decrementItem(item.name),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => cart.addItem(item.name, item.price),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => cart.removeItem(item.name),
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
                  Text("Total: ₱${cart.totalAmount.toStringAsFixed(2)}", style: TextStyle(fontSize: 18)),
                  ElevatedButton(
                    onPressed: () {
                      _showReceivedAmountDialog(context, cart);
                    },
                    child: Text("Proceed to Payment"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceivedAmountDialog(BuildContext context, CartProvider cart) {
    final TextEditingController _receivedAmountController = TextEditingController();

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
                if (receivedAmount < cart.totalAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Received amount is less than total price')),
                  );
                } else {
                  Navigator.of(context).pop();
                  _showPaymentSummaryDialog(context, cart, receivedAmount);
                }
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentSummaryDialog(BuildContext context, CartProvider cart, double receivedAmount) {
    double balance = receivedAmount - cart.totalAmount;
    DateTime now = DateTime.now();

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
              ...cart.items.values.map((item) {
                double itemTotal = item.price * item.quantity;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text("x ${item.quantity}  ₱${itemTotal.toStringAsFixed(2)}"),
                    ],
                  ),
                );
              }).toList(),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Amount Due", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₱${cart.totalAmount.toStringAsFixed(2)}"),
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
              onPressed: () async {
                Navigator.of(context).pop();

                // Create receipt data
                Map<String, dynamic> receipt = {
                  'referenceNumber': now.millisecondsSinceEpoch.toString(),
                  'date': now,
                  'time': DateFormat('HH:mm').format(now),
                  'dayOfWeek': DateFormat('EEEE').format(now),
                  'totalAmount': cart.totalAmount,
                  'receivedAmount': receivedAmount,
                  'balance': balance,
                  'items': cart.items.map((key, item) => MapEntry(key, {
                    'name': item.name,
                    'quantity': item.quantity,
                    'price': item.price,
                  })),
                };

                // Save the receipt to Firestore
                await FirebaseFirestore.instance.collection('Receipt').add(receipt);

                // Update Firebase stock
                await cart.updateFirebaseStock();

                // Clear cart after checkout
                cart.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Checkout completed successfully!')),
                );
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}