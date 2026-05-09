import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final service = FirestoreService();
  int selectedTab = 0;
  int totalListings = 0;
  int totalFavourites = 0;
  double avgPrice = 0;
  
  Map<String, int> listingCategory = {};
  Map<String, int> favCategory = {};
  Map<String, double> avgPriceByCategory = {};
  
  bool isLoading = true;
  String? errorMessage;

  static const Color _orange = Color(0xFFFF9900);
  static const Color _blue = Color(0xFF2F6FED);
  static const Color _navy = Color(0xFF223247);
  static const Color _bg = Color(0xFFF6F8FB);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F2);
  static const Color _textPrimary = Color(0xFF1F2D3D);
  static const Color _textSecondary = Color(0xFF8A9AB0);


  static const List<Color> catColors = [
    _blue,              // Electronics 
    Colors.deepPurple, // Books
    Colors.pink,       // Clothes
    Colors.brown,      // Furniture
    Colors.green,      // Sports & Fitness
    _navy,             // Daily Essentials 
    _orange,           // Leisure & Hobbies 
    _navy,             // Others 
  ];

  static const List<String> _categories = [
    'Electronics',
    'Books',
    'Clothes',
    'Furniture',
    'Sports & Fitness',
    'Daily Essentials',
    'Leisure & Hobbies',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String _normalizeCategory(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return 'Others';
    if (_categories.contains(value)) return value;
    return 'Others';
  }

  Future<void> loadData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      int newTotalListings = 0;
      int newTotalFavourites = 0;
      double newAvgPrice = 0;
      
      final Map<String, int> newListingCategory = {};
      final Map<String, int> newFavCategory = {};
      final Map<String, double> newAvgPriceByCategory = {};

      // My Listings
      final myProductsSnapshot = await service.getMyProducts().first;
      final products = myProductsSnapshot.docs;
      newTotalListings = products.length;
      
      double totalPrice = 0;
      final Map<String, double> catPriceSum = {};
      final Map<String, int> catPriceCount = {};

      for (final doc in products) {
        final data = doc.data() as Map<String, dynamic>;
        final price = (data['price'] ?? 0).toDouble();
        final category = _normalizeCategory(data['category']);

        totalPrice += price;
        newListingCategory[category] = (newListingCategory[category] ?? 0) + 1;
        catPriceSum[category] = (catPriceSum[category] ?? 0) + price;
        catPriceCount[category] = (catPriceCount[category] ?? 0) + 1;
      }
      
      newAvgPrice = products.isNotEmpty ? totalPrice / products.length : 0;
      
      for (final cat in catPriceSum.keys) {
        final count = catPriceCount[cat] ?? 0;
        if (count > 0) {
          newAvgPriceByCategory[cat] = catPriceSum[cat]! / count;
        }
      }

      // Favourites
      final favSnapshot = await service.getFavourites().first;
      int validFavCount = 0;
      
      for (final fav in favSnapshot.docs) {
        final productId = fav['productId'];
        try {
          final productDoc = await service.getProductById(productId);
          if (productDoc.exists) {
            validFavCount++;
            final data = productDoc.data() as Map<String, dynamic>;
            final category = _normalizeCategory(data['category']);
            newFavCategory[category] = (newFavCategory[category] ?? 0) + 1;
          } else {
            await service.removeFavourite(productId);
          }
        } catch (e) {
          // Skip broken favourite item
        }
      }
      
      newTotalFavourites = validFavCount;

      if (!mounted) return;
      setState(() {
        totalListings = newTotalListings;
        totalFavourites = newTotalFavourites;
        avgPrice = newAvgPrice;
        listingCategory = newListingCategory;
        favCategory = newFavCategory;
        avgPriceByCategory = newAvgPriceByCategory;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load insights. Pull to refresh and try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String get chartTitle {
    if (selectedTab == 0) return 'Posted Listings by Category';
    if (selectedTab == 1) return 'Favourites by Category';
    return 'Avg Price by Category (RM)';
  }

  String _getInsight() {
    if (selectedTab == 0 && listingCategory.isNotEmpty) {
      final top = listingCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      return 'Most of your posted listings are in the $top category.';
    }
    if (selectedTab == 1 && favCategory.isNotEmpty) {
      final top = favCategory.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      return 'You mostly favourite items from the $top category.';
    }
    if (selectedTab == 2 && avgPriceByCategory.isNotEmpty) {
      final top = avgPriceByCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
      return '${top.key} has the highest avg price at RM ${top.value.toStringAsFixed(0)}.';
    }
    return 'No data available yet.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Insights',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: _surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _navy),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _border, height: 1),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : RefreshIndicator(
              onRefresh: loadData,
              color: _blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.18)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        _statChip(0, '$totalListings', 'Listings'),
                        const SizedBox(width: 10),
                        _statChip(1, '$totalFavourites', 'Favourites'),
                        const SizedBox(width: 10),
                        _statChip(
                          2,
                          avgPrice == 0 ? '-' : 'RM ${avgPrice.toStringAsFixed(0)}',
                          'Avg Price',
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      chartTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: SizedBox(
                        height: 220,
                        child: selectedTab == 2
                            ? _buildAvgPriceChart()
                            : _buildCountChart(selectedTab == 0 ? listingCategory : favCategory),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Category Breakdown',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: Column(
                        children: _categories.asMap().entries.map((e) {
                          final color = catColors[e.key];
                          if (selectedTab == 2) {
                            final avg = avgPriceByCategory[e.value] ?? 0;
                            final maxAvg = avgPriceByCategory.values.isEmpty
                                ? 1.0
                                : avgPriceByCategory.values.reduce((a, b) => a > b ? a : b);
                            return _avgPriceRow(e.value, avg, maxAvg == 0 ? 0 : avg / maxAvg, color);
                          } else {
                            final data = selectedTab == 0 ? listingCategory : favCategory;
                            final count = data[e.value] ?? 0;
                            final total = data.values.fold(0, (s, v) => s + v);
                            return _categoryRow(e.value, count, total == 0 ? 0 : count / total, color);
                          }
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Insight',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: _blue, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _getInsight(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: _blue,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statChip(int index, String value, String label) {
    final selected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _orange : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _orange : _border,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white.withOpacity(0.85) : _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountChart(Map<String, int> data) {
    final entries = _categories.map((c) => MapEntry(c, data[c] ?? 0)).toList();
    final maxY = entries.map((e) => e.value.toDouble()).fold(0.0, (a, b) => a > b ? a : b) + 1;

    if (entries.every((e) => e.value == 0)) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value.toDouble(),
                color: catColors[e.key],
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(
          entries.map((e) => e.key).toList(),
          topValues: entries.map((e) => e.value == 0 ? '' : '${e.value}').toList(),
        ),
      ),
    );
  }

  Widget _buildAvgPriceChart() {
    final entries = _categories.map((c) => MapEntry(c, avgPriceByCategory[c] ?? 0.0)).toList();
    final maxY = entries.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b) * 1.2;

    if (entries.every((e) => e.value == 0)) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY,
        barGroups: entries.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: catColors[e.key],
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.black.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titlesData(
          entries.map((e) => e.key).toList(),
          topValues: entries.map((e) => e.value == 0 ? '' : 'RM${e.value.toStringAsFixed(0)}').toList(),
        ),
      ),
    );
  }

  FlTitlesData _titlesData(List<String> labels, {required List<String> topValues}) {
    return FlTitlesData(
      topTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i >= topValues.length || topValues[i].isEmpty) return const SizedBox();
            return Text(
              topValues[i],
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i >= labels.length) return const SizedBox();
            String label = labels[i];
            if (label == 'Sports & Fitness') label = 'Sports';
            if (label == 'Daily Essentials') label = 'Daily';
            if (label == 'Leisure & Hobbies') label = 'Leisure';
            if (label.length > 5) label = label.substring(0, 5);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, color: _textSecondary),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _categoryRow(String label, int count, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.black.withOpacity(0.06),
                color: color,
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avgPriceRow(String label, double avg, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.black.withOpacity(0.06),
                color: color,
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              avg == 0 ? '-' : 'RM${avg.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: _textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
