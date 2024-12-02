import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart_provider.dart';

class POSItem extends StatelessWidget {
  final String itemName;
  final double price;
  final int stock;
  final String imageUrl;

  const POSItem({
    super.key,
    required this.itemName,
    required this.price,
    required this.stock,
    required this.imageUrl
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.items[itemName]?.quantity ?? 0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Text(
              itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14.0,
                fontWeight: FontWeight.w600
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '₱${price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14.0,
                fontWeight: FontWeight.w500
              ),
            ),
            Text(
              stock > 0 ? 'In Stock: $stock' : 'Out of Stock',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: stock > 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.red),
                  onPressed: quantity > 0
                      ? () => cart.decrementItem(itemName)
                      : null,
                ),
                Text('$quantity'),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.green),
                  onPressed: stock > quantity
                      ? () => cart.addItem(itemName, price)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}