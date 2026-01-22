import 'dart:convert';
import 'package:http/http.dart' as http;

class CarSearchService {
  // Google Custom Search Paraméterek
  final String _cx = '93709af816e1c41a1';
  final String _apiKey = 'AIzaSyDD4A4DD_jUj6t0TCxyCiAxE1wHhqjh3Cg'; 

  Future<double?> fetchMarketMedianPrice({
    required String make, 
    required String model, 
    required int year,
    String? fuelType,
    String? engineSize,
    String? power,
    String? transmission,
  }) async {
    try {
      // Összetettebb, pontosabb keresési lekérdezés összeállítása
      String query = 'eladó $make $model $year';
      if (engineSize != null && engineSize.isNotEmpty) query += ' $engineSize cm3';
      if (fuelType != null) query += ' $fuelType';
      if (power != null && power.isNotEmpty) query += ' $power';
      if (transmission != null) query += ' $transmission';
      query += ' ár HUF';

      print('🌐 AI Keresés indítása: $query');

      final url = Uri.parse(
        'https://www.googleapis.com/customsearch/v1?key=$_apiKey&cx=$_cx&q=${Uri.encodeComponent(query)}'
      );

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? items = data['items'];

        if (items == null || items.isEmpty) return null;

        List<int> foundPrices = [];
        final RegExp priceRegex = RegExp(
          r'(\d[\d\s\.]{4,10})\s*(?:Ft|HUF|forint)',
          caseSensitive: false,
        );

        for (var item in items) {
          final String textToSearch = '${item['title']} ${item['snippet']}';
          final matches = priceRegex.allMatches(textToSearch);

          for (var match in matches) {
            String priceStr = match.group(1) ?? '';
            priceStr = priceStr.replaceAll(RegExp(r'[\s\.]'), '');
            int? price = int.tryParse(priceStr);
            
            if (price != null && price > 100000) {
              foundPrices.add(price);
            }
          }
        }

        if (foundPrices.isEmpty) return null;

        foundPrices.sort();
        double median;
        int middle = foundPrices.length ~/ 2;
        if (foundPrices.length % 2 == 1) {
          median = foundPrices[middle].toDouble();
        } else {
          median = (foundPrices[middle - 1] + foundPrices[middle]) / 2.0;
        }

        return median;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ SearchService hiba: $e');
      return null;
    }
  }
}
