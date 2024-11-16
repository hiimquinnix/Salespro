import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class ForecastPage extends StatefulWidget {
  @override
  _ForecastPageState createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> with SingleTickerProviderStateMixin {
  List<double> _monthlySales = [];
  double _forecastedSales = 0.0;
  double _growthRate = 0.0;
  Map<String, double> _forecastData = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Receipt')
          .orderBy('date', descending: true)
          .limit(12)
          .get();

      Map<String, double> monthlySalesMap = {};

      snapshot.docs.forEach((doc) {
        DateTime date;
        if (doc['date'] is Timestamp) {
          date = (doc['date'] as Timestamp).toDate();
        } else if (doc['date'] is String) {
          date = DateTime.parse(doc['date']);
        } else {
          print('Unsupported date format for document ${doc.id}');
          return;
        }

        String monthKey = DateFormat('yyyy-MM').format(date);
        double amount = (doc['totalAmount'] is num) 
            ? (doc['totalAmount'] as num).toDouble() 
            : double.tryParse(doc['totalAmount'].toString()) ?? 0.0;

        monthlySalesMap.update(monthKey, (value) => value + amount, ifAbsent: () => amount);
      });

      setState(() {
        _monthlySales = monthlySalesMap.values.toList().reversed.toList();
      });

      await Future.delayed(Duration(seconds: 3));

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
        title: Text('Sales Forecasting'),
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
                  SizedBox(height: 20),
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
                    padding: EdgeInsets.all(16),
                    color: Colors.green.shade700,
                    child: Column(
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
                        _buildSalesChart(),
                        SizedBox(height: 24),
                        _buildForecastTable(),
                        SizedBox(height: 24),
                        _buildGrowthRateCard(),
                      ],
                    ),
                  ),
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
            Text(
              '${_growthRate.toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
}