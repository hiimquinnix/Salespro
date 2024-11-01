import 'package:flutter/material.dart';

class ShiftPage extends StatelessWidget {
  const ShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Open shift"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start 
          children: [
            const SizedBox(height: 20), // Space below the AppBar
            const Text(
              "Specify the cash amount in your drawer at the start of the shift",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Bigger text
            ),
            const SizedBox(height: 20), // Space between the texts
            const Text(
              "Amount:",
              style: TextStyle(fontSize: 12), // Smaller text for "Amount"
            ),
            const SizedBox(height: 10), // Space between "Amount" and TextField
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '₱ 0.00', // Peso currency sample
              ),
              keyboardType: TextInputType.number, // Numeric keyboard for entering amounts
            ),
            const SizedBox(height: 20), // Space between text field and button
            Center(
              child: SizedBox(
                width: 200, // Increase button width
                height: 50,  // Increase button height
                child: OutlinedButton(
                  onPressed: () {
                    print("Shift opened");
                  },
                  child: const Text(
                    "OPEN SHIFT",
                    style: TextStyle(fontSize: 16), // Make button text bigger
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: ShiftPage(),
  ));
}
