import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  ForecastPageState createState() => ForecastPageState();
}

class ForecastPageState extends State<ForecastPage> with SingleTickerProviderStateMixin {
  List<double> _monthlySales = [];
  double _forecastedSales = 0.0;
  double _growthRate = 0.0;
  final Map<String, double> _forecastData = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<MapEntry<String, int>> _topSellingItems = [];
  List<MapEntry<String, int>> _lowStockItems = [];
  bool _isLoadingStock = true;

  final currencyFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
    _fetchSalesData();
    _fetchStockLevels();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesData() async {
    try {
      QuerySnapshot receiptSnapshot = await FirebaseFirestore.instance
          .collection('Receipt')
          .orderBy('date', descending: true)
          .limit(12)
          .get();

      Map<String, double> monthlySalesMap = {};
      Map<String, int> itemSalesCount = {};

      for (var doc in receiptSnapshot.docs) {
        DateTime date;
        if (doc['date'] is Timestamp) {
          date = (doc['date'] as Timestamp).toDate();
        } else if (doc['date'] is String) {
          date = DateTime.parse(doc['date']);
        } else {
          print('Unsupported date format for document ${doc.id}');
          continue;
        }

        String monthKey = DateFormat('yyyy-MM').format(date);
        double amount = (doc['totalAmount'] is num)
            ? (doc['totalAmount'] as num).toDouble()
            : double.tryParse(doc['totalAmount'].toString()) ?? 0.0;

        monthlySalesMap.update(monthKey, (value) => value + amount, ifAbsent: () => amount);

        var items = doc['items'];
        if (items != null) {
          (items as Map<String, dynamic>).forEach((key, itemData) {
            if (itemData is Map<String, dynamic>) {
              String itemName = itemData['name'] ?? '';
              int quantity = (itemData['quantity'] is num)
                  ? (itemData['quantity'] as num).toInt()
                  : 1;

              if (itemName.isNotEmpty) {
                itemSalesCount.update(
                  itemName,
                  (value) => value + quantity,
                  ifAbsent: () => quantity
                );
              }
            }
          });
        }
      }

      _topSellingItems = itemSalesCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      _topSellingItems = _topSellingItems.take(3).toList();

      setState(() {
        _monthlySales = monthlySalesMap.values.toList().reversed.toList();
      });

      _calculateForecast();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching sales data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching sales data. Please try again later.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchStockLevels() async {
    try {
      QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
          .collection('Items')
          .get();

      Map<String, int> stockLevels = {};
      List<MapEntry<String, int>> lowStockItems = [];

      for (var doc in itemsSnapshot.docs) {
        String itemName = doc['name'] ?? '';
        int stockQuantity = 0;
        var rawStock = doc['stocks'];
        if (rawStock != null) {
          if (rawStock is num) {
            stockQuantity = rawStock.toInt();
          } else if (rawStock is String) {
            stockQuantity = int.tryParse(rawStock) ?? 0;
          }
        }


        if (itemName.isNotEmpty) {
          stockLevels[itemName] = stockQuantity;
          if (stockQuantity < 20) { // Assuming low stock threshold is 10
            lowStockItems.add(MapEntry(itemName, stockQuantity));
          }
        }
      }

      // Sort low stock items by quantity
      lowStockItems.sort((a, b) => a.value.compareTo(b.value));

      setState(() {
        _lowStockItems = lowStockItems;
        _isLoadingStock = false;
      });
    } catch (e) {
      print('Error fetching stock levels: $e');
      setState(() {
        _isLoadingStock = false;
      });
    }
  }

  void _calculateForecast() {
    if (_monthlySales.isEmpty) return;

    double totalGrowth = 0;
    for (int i = 1; i < _monthlySales.length; i++) {
      if (_monthlySales[i - 1] != 0) {
        totalGrowth += (_monthlySales[i] - _monthlySales[i - 1]) / _monthlySales[i - 1];
      }
    }
    _growthRate = (totalGrowth / (_monthlySales.length - 1)) * 100;

    _forecastedSales = _monthlySales.last * (1 + _growthRate / 100);

    _forecastData['1 Month'] = _forecastedSales;
    _forecastData['3 Months'] = _monthlySales.last * pow(1 + _growthRate / 100, 3);
    _forecastData['6 Months'] = _monthlySales.last * pow(1 + _growthRate / 100, 6);
    _forecastData['1 Year'] = _monthlySales.last * pow(1 + _growthRate / 100, 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Forecasting'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _animation,
                    child: Icon(Icons.bar_chart, size: 100, color: Colors.green.shade700),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Generating your forecast...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.green.shade700,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Forecast',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Based on historical data',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopSellingItemsCard(),
                        SizedBox(height: 24),
                        _buildSalesChart(),
                        SizedBox(height: 24),
                        _buildForecastTable(),
                        SizedBox(height: 24),
                        _buildGrowthRateCard(),
                        SizedBox(height: 24),
                        _buildStockRecommendationCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopSellingItemsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 3 Selling Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._topSellingItems.asMap().entries.map((entry) {
              int index = entry.key;
              MapEntry<String, int> item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${index + 1}. ${item.key}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Sold: ${item.value}',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Monthly Sales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index % 2 == 0 && index < _monthlySales.length) {
                            return Text('M${index + 1}');
                          }
                          return Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlySales.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green.shade700,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.shade100.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastTable() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast Projections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Table(
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
              },
              children: _forecastData.entries.map((entry) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        currencyFormat.format(entry.value),
                        style: TextStyle(color: Colors.green.shade700),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthRateCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated Monthly Growth Rate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 32,
                  color: _growthRate >= 0 ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  '${_growthRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _growthRate >= 0 ? Colors.green.shade700 : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              _growthRate >= 0
                  ? 'Your business is growing!'
                  : 'Your business is facing some challenges. Consider reviewing your strategies.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockRecommendationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingStock)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (_isLoadingStock)
              Text('Loading stock information...')
            else if (_lowStockItems.isEmpty)
              Text(
                'All items are well-stocked!',
                style: TextStyle(fontSize: 16, color: Colors.green.shade700),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consider restocking the following items:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 150,
                    child: ListView.builder(
                      itemCount: _lowStockItems.length,
                      itemBuilder: (context, index) {
                        final item = _lowStockItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.key,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Stock: ${item.value}',
                                style: TextStyle(
                                  color: item.value < 10 ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

