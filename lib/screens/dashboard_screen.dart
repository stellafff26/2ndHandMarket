import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final service = FirestoreService();

  int selectedTab = 0;

  int totalListings = 0;
  int totalFavourites = 0;
  double avgPrice = 0;

  Map<String, int> listingCategory = {};
  Map<String, int> favCategory = {};
  Map<String, int> priceData = {
    "0-50": 0,
    "50-100": 0,
    "100+": 0,
  };

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    final myProducts = await service.getMyProducts().first;
    final products = myProducts.docs;

    totalListings = products.length;
    totalFavourites = await service.getMyFavouriteCount();

    listingCategory.clear();
    favCategory.clear();
    priceData = {"0-50": 0, "50-100": 0, "100+": 0};

    double totalPrice = 0;

    for (var doc in products) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0).toDouble();
      final category = data['category'] ?? "Others";

      totalPrice += price;

      listingCategory[category] =
          (listingCategory[category] ?? 0) + 1;

      if (price <= 50) {
        priceData["0-50"] = priceData["0-50"]! + 1;
      } else if (price <= 100) {
        priceData["50-100"] = priceData["50-100"]! + 1;
      } else {
        priceData["100+"] = priceData["100+"]! + 1;
      }
    }

    avgPrice = products.isNotEmpty ? totalPrice / products.length : 0;

    final favSnapshot = await service.getFavourites().first;

    for (var fav in favSnapshot.docs) {
      final productId = fav['productId'];
      final doc = await service.getProductById(productId);

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final cat = data['category'] ?? "Others";

        favCategory[cat] = (favCategory[cat] ?? 0) + 1;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Insights")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== SUMMARY =====
            Row(
              children: [
                _card("Listings", totalListings, 0),
                _card("Favourites", totalFavourites, 1),
                _card("Avg RM", avgPrice.toInt(), 2),
              ],
            ),

            const SizedBox(height: 36),

            // ===== CHART =====
            SizedBox(
              height: 240,
              child: selectedTab == 0
                  ? _buildChart("Listings by Category", listingCategory)
                  : selectedTab == 1
                      ? _buildChart("Favourites by Category", favCategory)
                      : _buildChart("Price Distribution", priceData),
            ),

            const SizedBox(height: 16),

            // ===== INSIGHT =====
            _buildInsight(),

          ],
        ),
      ),
    );
  }

  Widget _card(String title, num value, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? Colors.orange : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(String title, Map<String, int> data) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: _bars(data),
              titlesData: _titles(data.keys.toList(), data),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _bars(Map<String, int> data) {
    final entries = data.entries.toList();

    return List.generate(entries.length, (i) {

      final value = entries[i].value;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  FlTitlesData _titles(List<String> labels, Map<String, int> data) {

    final values = data.values.toList();

    return FlTitlesData(

      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 20,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= values.length) return const SizedBox();
            return Text(
              values[value.toInt()].toString(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),

      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),

      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),

      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= labels.length) return const SizedBox();
            return Text(labels[value.toInt()],
                style: const TextStyle(fontSize: 10));
          },
        ),
      ),
    );
  }

  Widget _buildInsight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Insight",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getInsight(),
            style: const TextStyle(height: 1.4),
          ),
        ),
      ],
    );
  }

  String _getInsight() {

    if (selectedTab == 0 && listingCategory.isNotEmpty) {
      final top = listingCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      return "Most of your listings are in $top category.";
    }

    if (selectedTab == 1 && favCategory.isNotEmpty) {
      final top = favCategory.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      return "You mostly favourite items from $top category.";
    }

    if (selectedTab == 2) {
      return "Your average price is RM ${avgPrice.toStringAsFixed(0)}.";
    }

    return "No data available.";
  }
}