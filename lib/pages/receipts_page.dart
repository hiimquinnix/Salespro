import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptsPage extends StatelessWidget {
  final List<Map<String, dynamic>> receipts; // Receipts passed from CheckoutPage

  const ReceiptsPage({super.key, required this.receipts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipts History"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          return ListTile(
            leading: Icon(Icons.receipt, color: Colors.green),
            title: Text("Reference: ${receipt['referenceNumber']}"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date: ${DateFormat('yyyy-MM-dd').format(receipt['date'])}"),
                Text("Time: ${receipt['time']}"),
                Text("Day: ${receipt['dayOfWeek']}"),
                Text("Total: ₱${receipt['totalAmount'].toStringAsFixed(2)}"),
                Text("Received: ₱${receipt['receivedAmount'].toStringAsFixed(2)}"),
                Text("Balance: ₱${receipt['balance'].toStringAsFixed(2)}"),
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
