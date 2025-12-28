// lib/services/statistics_service.dart
import 'dart:math';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';

class MonthlyStats {
  final double totalCost;
  final double totalLiters;
  final int totalDistance;
  final double avgConsumption;
  final double avgCostPerKm;
  final double avgPrice;

  MonthlyStats({
    this.totalCost = 0,
    this.totalLiters = 0,
    this.totalDistance = 0,
    this.avgConsumption = 0,
    this.avgCostPerKm = 0,
    this.avgPrice = 0,
  });
}

class StatisticsService {
  
  MonthlyStats calculateMonthlyStats(List<Szerviz> allServices, DateTime selectedMonth) {
    allServices.sort((a, b) => a.date.compareTo(b.date));

    double monthlyCost = 0;
    double monthlyLiters = 0;
    int monthlyDistance = 0;
    double consumableLiters = 0;

    for (int i = 0; i < allServices.length; i++) {
      final service = allServices[i];
      if (!service.description.toLowerCase().contains('tankolás')) continue;

      double currentLiters = 0;
      try {
        final parts = service.description.split('(');
        if (parts.length > 1) {
          final literPart = parts[1].split(' ')[0].replaceAll(',', '.');
          currentLiters = double.tryParse(literPart) ?? 0;
        }
      } catch (e) { /* ignore */ }

      if (service.date.year == selectedMonth.year && service.date.month == selectedMonth.month) {
        monthlyCost += service.cost;
        monthlyLiters += currentLiters;

        Szerviz? prevService;
        for (int j = i - 1; j >= 0; j--) {
          if (allServices[j].description.toLowerCase().contains('tankolás')) {
            prevService = allServices[j];
            break;
          }
        }

        if (prevService != null) {
          int dist = service.mileage - prevService.mileage;
          if (dist > 0) {
            monthlyDistance += dist;
            double prevLiters = 0;
             try {
              final parts = prevService.description.split('(');
              if (parts.length > 1) {
                final literPart = parts[1].split(' ')[0].replaceAll(',', '.');
                prevLiters = double.tryParse(literPart) ?? 0;
              }
            } catch (e) { /* ignore */ }
            consumableLiters += prevLiters;
          }
        }
      }
    }

    final double avgPrice = monthlyLiters > 0 ? monthlyCost / monthlyLiters : 0;
    final double avgConsumption = monthlyDistance > 0 ? (consumableLiters / monthlyDistance) * 100 : 0;
    final double avgCostPerKm = monthlyDistance > 0 ? (consumableLiters * avgPrice) / monthlyDistance : 0;

    return MonthlyStats(
      totalCost: monthlyCost,
      totalLiters: monthlyLiters,
      totalDistance: monthlyDistance,
      avgConsumption: avgConsumption,
      avgCostPerKm: avgCostPerKm,
      avgPrice: avgPrice,
    );
  }

  // --- ÚJ / MÓDOSÍTOTT FUNKCIÓK ---

  List<Szerviz> getTopExpenses(List<Szerviz> services) {
    final sorted = List<Szerviz>.from(services);
    sorted.sort((a, b) => b.cost.compareTo(a.cost));
    return sorted.take(5).toList();
  }

  Map<String, double> getYearlyComparison(List<Szerviz> services) {
    final now = DateTime.now();
    double thisYear = 0;
    double lastYear = 0;

    for (var s in services) {
      if (s.date.year == now.year) {
        thisYear += s.cost;
      } else if (s.date.year == now.year - 1) {
        lastYear += s.cost;
      }
    }
    return {'thisYear': thisYear, 'lastYear': lastYear};
  }

  Map<String, double> getFixedCostsBreakdown(List<Szerviz> services) {
    final now = DateTime.now();
    final Map<String, double> breakdown = {};
    
    for (var s in services) {
      if (s.date.year == now.year) {
        final desc = s.description.toLowerCase();
        if (desc.contains('biztosítás') || desc.contains('casco') || desc.contains('adó') || desc.contains('műszaki') || desc.contains('matrica')) {
          breakdown[s.description] = (breakdown[s.description] ?? 0) + s.cost;
        }
      }
    }
    return breakdown;
  }

  // JAVÍTOTT: Szerviz statisztikák (tankolás és emlékeztető alap nélkül)
  Map<String, dynamic> getServiceStats(List<Szerviz> services) {
    // Csak a valódi szervizek
    final realServices = services.where((s) => 
      !s.description.toLowerCase().contains('tankolás') && 
      !s.description.toLowerCase().startsWith('emlékeztető alap')
    ).toList();

    realServices.sort((a, b) => a.date.compareTo(b.date));

    // 1. Elmúlt 12 hónap darabszáma
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final countLastYear = realServices.where((s) => s.date.isAfter(oneYearAgo)).length;

    // 2. Átlagos km intervallum
    int avgKmInterval = 0;
    if (realServices.length >= 2) {
      int totalInterval = 0;
      int intervalsCount = 0;
      for (int i = 1; i < realServices.length; i++) {
        final diff = realServices[i].mileage - realServices[i-1].mileage;
        if (diff > 0) { // Csak ha nőtt a km
          totalInterval += diff;
          intervalsCount++;
        }
      }
      if (intervalsCount > 0) {
        avgKmInterval = (totalInterval / intervalsCount).round();
      }
    }

    return {
      'countLastYear': countLastYear,
      'avgKmInterval': avgKmInterval,
      'totalCount': realServices.length,
    };
  }

  double getAverageDailyKm(List<Szerviz> services) {
    if (services.length < 2) return 0;
    services.sort((a, b) => a.date.compareTo(b.date));
    
    final first = services.first;
    final last = services.last;
    final days = last.date.difference(first.date).inDays;
    
    if (days == 0) return 0;
    return (last.mileage - first.mileage) / days;
  }

  Map<String, dynamic> predictOilChange(List<Szerviz> services) {
    final dailyKm = getAverageDailyKm(services);
    if (dailyKm == 0) return {};

    try {
      final lastOilChange = services.lastWhere((s) => s.description.toLowerCase().contains('olajcsere'));
      final currentMileage = services.last.mileage;
      final kmSinceChange = currentMileage - lastOilChange.mileage;
      final kmLeft = 15000 - kmSinceChange;
      
      final daysLeft = kmLeft / dailyKm;
      final predictedDate = DateTime.now().add(Duration(days: daysLeft.toInt()));
      
      return {
        'date': predictedDate,
        'daysLeft': daysLeft.toInt(),
        'kmLeft': kmLeft
      };
    } catch (e) {
      return {};
    }
  }

  int? getDaysUntilDeadline(List<Szerviz> services, String type) {
    try {
      final lastEvent = services.lastWhere((s) => s.description.toLowerCase().contains(type.toLowerCase()));
      if (lastEvent.date.isAfter(DateTime.now())) {
        return lastEvent.date.difference(DateTime.now()).inDays;
      }
      final int validityDays = type.contains('műszaki') ? 730 : 365; 
      final deadline = lastEvent.date.add(Duration(days: validityDays));
      return deadline.difference(DateTime.now()).inDays;
    } catch (e) {
      return null;
    }
  }

  Szerviz? findLastServiceByDescription(List<Szerviz> services, String description) {
    try {
      final filtered = services.where((s) => s.description.toLowerCase().contains(description.toLowerCase())).toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));
      return filtered.first;
    } catch (e) {
      return null;
    }
  }
  
  double calculateTotalCost(List<Szerviz> services) {
    if (services.isEmpty) return 0;
    return services.map((s) => s.cost).reduce((a, b) => a + b).toDouble();
  }
}
