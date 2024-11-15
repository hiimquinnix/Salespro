import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key, required List receipts});

  @override
  _ReceiptsPageState createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  String selectedTimeFilter = 'Week'; // Default filter is 'Week'
  late Future<List<Map<String, dynamic>>> receiptsFuture;
  TextEditingController yearController = TextEditingController();
  TextEditingController monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    receiptsFuture = fetchReceipts();
  }

  // Fetch receipts from Firestore and parse them
  Future<List<Map<String, dynamic>>> fetchReceipts() async {
    // Reference the 'Receipt' collection in Firebase
    final snapshot = await FirebaseFirestore.instance.collection('Receipt').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'referenceNumber': data['referenceNumber'] ?? '',
        // Use the date directly from Firestore (without changing it to today)
        'date': (data['date'] is Timestamp) ? (data['date'] as Timestamp).toDate() : DateTime.now(),
        'time': data['time'] ?? '',
        'dayOfWeek': data['dayOfWeek'] ?? '',
        'totalAmount': double.tryParse(data['totalAmount']?.toString() ?? '0') ?? 0,
        'receivedAmount': double.tryParse(data['receivedAmount']?.toString() ?? '0') ?? 0,
        'balance': double.tryParse(data['balance']?.toString() ?? '0') ?? 0,
      };
    }).toList();
  }

  // Filter the receipts based on the selected time filter (week, month, year, today)
  Future<List<Map<String, dynamic>>> filterReceipts(List<Map<String, dynamic>> receipts) async {
    DateTime now = DateTime.now();
    switch (selectedTimeFilter) {
      case 'Week':
        return receipts.where((receipt) {
          DateTime receiptDate = receipt['date'];
          return receiptDate.isAfter(now.subtract(Duration(days: now.weekday))) && 
                 receiptDate.isBefore(now.add(Duration(days: 7 - now.weekday)));
        }).toList();

      case 'Month':
        return receipts.where((receipt) {
          DateTime receiptDate = receipt['date'];
          return receiptDate.month == now.month && receiptDate.year == now.year;
        }).toList();

      case 'Year':
        // Filtering by user-selected year (you can set it via an input box)
        int selectedYear = int.tryParse(yearController.text) ?? now.year;
        return receipts.where((receipt) {
          DateTime receiptDate = receipt['date'];
          return receiptDate.year == selectedYear;
        }).toList();

      case 'Today':
        return receipts.where((receipt) {
          DateTime receiptDate = receipt['date'];
          return receiptDate.year == now.year &&
                 receiptDate.month == now.month &&
                 receiptDate.day == now.day;
        }).toList();

      default:
        return receipts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Receipts History"),
        backgroundColor: Colors.green,
        actions: [
          // Dropdown to filter by Today, Week, Month, or Year
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                selectedTimeFilter = value;
                receiptsFuture = fetchReceipts().then((receipts) => filterReceipts(receipts));
              });
            },
            itemBuilder: (BuildContext context) {
              return {'Today', 'Week', 'Month', 'Year'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Year and Month Inputs for custom filtering
          if (selectedTimeFilter == 'Year' || selectedTimeFilter == 'Month') ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter Year (e.g. 2024)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    receiptsFuture = fetchReceipts().then((receipts) => filterReceipts(receipts));
                  });
                },
              ),
            ),
          ],
          if (selectedTimeFilter == 'Month') ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: monthController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Enter Month (1-12)",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    receiptsFuture = fetchReceipts().then((receipts) => filterReceipts(receipts));
                  });
                },
              ),
            ),
          ],
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(  // FutureBuilder to handle data fetching
              future: receiptsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final receipts = snapshot.data ?? [];

                if (receipts.isEmpty) {
                  return const Center(child: Text("No receipts available"));
                }

                return ListView.builder(
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return ListTile(
                      leading: const Icon(Icons.receipt, color: Colors.green),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
