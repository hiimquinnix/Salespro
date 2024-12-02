import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:salespro/cart_provider.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selected Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: cart.items.length,
                separatorBuilder: (context, index) => const Divider(),
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
                            icon: const Icon(Icons.remove),
                            onPressed: () => cart.decrementItem(item.name),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => cart.addItem(item.name, item.price),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => cart.removeItem(item.name),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: ₱${cart.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18)),
                  ElevatedButton(
                    onPressed: () {
                      _showReceivedAmountDialog(context, cart);
                    },
                    child: const Text("Proceed to Payment"),
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
    final TextEditingController receivedAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Received Amount"),
          content: TextField(
            controller: receivedAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "₱0.00"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                double receivedAmount = double.tryParse(receivedAmountController.text) ?? 0;
                if (receivedAmount < cart.totalAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Received amount is less than total price')),
                  );
                } else {
                  Navigator.of(context).pop();
                  _showPaymentSummaryDialog(context, cart, receivedAmount);
                }
              },
              child: const Text("OK"),
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
          title: const Text("Payment Summary"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
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
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount Due", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("₱${cart.totalAmount.toStringAsFixed(2)}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Amount Received"),
                  Text("₱${receivedAmount.toStringAsFixed(2)}"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Change", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text("₱${balance.toStringAsFixed(2)}"),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
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
                  const SnackBar(content: Text('Checkout completed successfully!')),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

