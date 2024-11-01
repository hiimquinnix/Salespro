import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Forecast',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SalesForecastPage(),
    );
  }
}

class SalesForecastPage extends StatefulWidget {
  @override
  _SalesForecastPageState createState() => _SalesForecastPageState();
}

class _SalesForecastPageState extends State<SalesForecastPage> {
  List<double> salesData = [];
  List<double> forecastData = [];
  String recommendation = '';

  @override
  void initState() {
    super.initState();
    generateSalesData();
    performForecast();
    generateRecommendation();
  }

  void generateSalesData() {
    final random = Random();
    for (int i = 0; i < 12; i++) {
      salesData.add(100 + random.nextDouble() * 50);
    }
  }

  void performForecast() {
    // Simple linear regression
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = salesData.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += salesData[i];
      sumXY += i * salesData[i];
      sumX2 += i * i;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    for (int i = 0; i < 6; i++) {
      forecastData.add(slope * (n + i) + intercept);
    }
  }

  void generateRecommendation() {
    double lastSale = salesData.last;
    double lastForecast = forecastData.last;

    if (lastForecast > lastSale * 1.1) {
      recommendation =
          'Increase inventory. Sales are projected to rise significantly.';
    } else if (lastForecast < lastSale * 0.9) {
      recommendation = 'Reduce inventory. Sales are projected to decline.';
    } else {
      recommendation =
          'Maintain current inventory levels. Sales are projected to remain stable.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Forecast'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales Forecast',
                style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 20),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: 17,
                  minY: 0,
                  maxY: 200,
                  lineBarsData: [
                    LineChartBarData(
                      spots: salesData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: forecastData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                              (e.key + salesData.length).toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.red,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Recommendation:',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            Text(recommendation, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
