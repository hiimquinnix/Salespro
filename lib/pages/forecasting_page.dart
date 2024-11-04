import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(SalesForecastingApp());
}

class SalesForecastingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Forecasting',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ForecastPage(),
    );
  }
}

class ForecastPage extends StatefulWidget {
  @override
  _ForecastPageState createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  final TextEditingController _totalSalesController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedTimeUnit = 'Days';
  double _forecastedSales = 0.0;
  double _growthPercentage = 0.0;
  Map<String, double> _forecastData = {};
  double _growthRate = 0.0; // For tracking growth rate

  void calculateForecast() {
    final double totalSales = double.tryParse(_totalSalesController.text) ?? 0.0;
    final int period = int.tryParse(_periodController.text) ?? 0;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date for the initial sales.')),
      );
      return;
    }

    // Generate random growth percentage between 1 and 50
    _growthRate = Random().nextDouble() * 49 + 1; // between 1 and 50
    print("Random Growth Rate: $_growthRate%"); // For debugging

    _forecastData.clear();

    double forecastMultiplier;
    switch (_selectedTimeUnit) {
      case 'Days':
        forecastMultiplier = period.toDouble();
        break;
      case 'Weeks':
        forecastMultiplier = period * 7.0;
        break;
      case 'Months':
        forecastMultiplier = period * 30.0; // Assume 30 days for a month
        break;
      case 'Years':
        forecastMultiplier = period * 365.0;
        break;
      default:
        forecastMultiplier = 0.0;
    }

    _forecastedSales = totalSales * (1 + (_growthRate / 100) * forecastMultiplier);
    if (totalSales > 0) {
      _growthPercentage = min(100, ((_forecastedSales - totalSales) / totalSales) * 100); // Cap growth percentage at 100%
    }

    // Populate forecast data for each time unit
    _forecastData['Days'] = totalSales * (1 + (_growthRate / 100) * 1);
    _forecastData['Weeks'] = totalSales * (1 + (_growthRate / 100) * 7);
    _forecastData['Months'] = totalSales * (1 + (_growthRate / 100) * 30);
    _forecastData['Years'] = totalSales * (1 + (_growthRate / 100) * 365);

    setState(() {});
  }

  void selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  DateTime calculateFutureDate(int period, String unit) {
    switch (unit) {
      case 'Days':
        return _selectedDate!.add(Duration(days: period));
      case 'Weeks':
        return _selectedDate!.add(Duration(days: period * 7));
      case 'Months':
        return DateTime(_selectedDate!.year, _selectedDate!.month + period, _selectedDate!.day);
      case 'Years':
        return DateTime(_selectedDate!.year + period, _selectedDate!.month, _selectedDate!.day);
      default:
        return _selectedDate!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sales Forecasting')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Forecast graph section at the top
            Text(
              'Forecasted Sales Over Time Units',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _forecastData.entries.map((entry) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('₱${entry.value.toStringAsFixed(2)}'),
                      Container(
                        height: entry.value / _forecastData.values.reduce((a, b) => a > b ? a : b) * 150,
                        width: 40,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 8.0),
                      Text(entry.key),
                    ],
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16.0),

            // Calculator section
            TextField(
              controller: _totalSalesController,
              decoration: InputDecoration(labelText: 'Total Sales Amount (₱)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 8.0),
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Select Sales Date'
                  : 'Selected Date: ${formatDate(_selectedDate!)}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () => selectDate(context),
            ),
            TextField(
              controller: _periodController,
              decoration: InputDecoration(labelText: 'Forecast Period (in $_selectedTimeUnit)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            DropdownButton<String>(
              value: _selectedTimeUnit,
              onChanged: (value) {
                setState(() {
                  _selectedTimeUnit = value!;
                });
              },
              items: ['Days', 'Weeks', 'Months', 'Years']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: calculateForecast,
              child: Text('Forecast'),
            ),
            if (_forecastedSales > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forecasted Sales: ₱${_forecastedSales.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    if (_selectedDate != null) ...[
                      SizedBox(height: 8.0),
                      Text(
                        'Forecast Target Date: ${formatDate(calculateFutureDate(int.tryParse(_periodController.text) ?? 0, _selectedTimeUnit))}',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ],
                ),
              ),
            if (_growthPercentage > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Growth Percentage: ${_growthPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
