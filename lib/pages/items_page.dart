import 'package:flutter/material.dart';

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Items"),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.list),
            title: const Text('Items'),
            onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/items');
              },
          ),
          
          ListTile(
            leading: Icon(Icons.local_offer),
            title: const Text('Discount'),
            onTap: () {
              // Action for Categories tap
            },
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: ItemsPage()));
