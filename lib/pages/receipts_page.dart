import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key});

  // Mock data to simulate receipt history
  List<Map<String, dynamic>> _generateMockReceipts() {
    final List<Map<String, dynamic>> receipts = [];
    final DateTime now = DateTime.now();
    
    for (int i = 0; i < 10; i++) {
      final date = now.subtract(Duration(days: i * 3));  // Example of past receipts
      receipts.add({
        "referenceNumber": "RECPT-${1000 + i}",
        "date": date,
        "time": DateFormat('hh:mm a').format(date),
        "dayOfWeek": DateFormat('EEEE').format(date),
      });
    }
    return receipts;
  }

  @override
  Widget build(BuildContext context) {
    final receipts = _generateMockReceipts();

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
              ],
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
