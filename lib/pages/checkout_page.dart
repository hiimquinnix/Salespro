import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Example order items (in a real app, you'd pass this data dynamically)
  final List<Map<String, dynamic>> _orderItems = [
    {'name': 'Apple', 'price': 1.50, 'quantity': 3},
    {'name': 'Banana', 'price': 0.80, 'quantity': 5},
    {'name': 'Bread', 'price': 2.50, 'quantity': 1},
  ];

  double _getTotalPrice() {
    return _orderItems.fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout Ticket'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.headlineSmall, // Updated to headlineSmall
            ),
            SizedBox(height: 16.0),
            // Order items displayed like a receipt
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling inside
              itemCount: _orderItems.length,
              itemBuilder: (context, index) {
                final item = _orderItems[index];
                return ListTile(
                  title: Text('${item['name']} x ${item['quantity']}'),
                  trailing: Text('₱${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                );
              },
            ),
            Divider(),
            ListTile(
              title: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text(
                '₱${_getTotalPrice().toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(),
            SizedBox(height: 24.0),
            Text(
              'Payment',
              style: Theme.of(context).textTheme.headlineSmall, // Updated to headlineSmall
            ),
            SizedBox(height: 16.0),
            // Placeholder for payment methods or summary
            ListTile(
              title: Text('Cash'),
              trailing: Text('₱${_getTotalPrice().toStringAsFixed(2)}'),
            ),
            Divider(),
            SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('Complete Purchase'),
                onPressed: () {
                  // Here you would typically send the order to your backend
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Processing Payment...')),
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
