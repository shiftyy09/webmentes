// lib/services/statistics_service.dart
import 'dart:math';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:intl/intl.dart';

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

  // SEGÉDFÜGGVÉNY: Eldönti egy bejegyzésről, hogy tankolás-e
  bool _isFuel(Szerviz s) {
    return s.description.toLowerCase().contains('tankolás');
  }

  // JAVÍTÁS: Univerzális liter kivonó (Regex alapú)
  double _extractLiters(String description) {
    try {
      // Megkeressük a zárójelek közötti részt: (11.2 L) vagy (11,2L) stb.
      final regex = RegExp(r'\(([\d.,]+)\s*[lL]?\)');
      final match = regex.firstMatch(description);
      if (match != null) {
        final valueStr = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(valueStr) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  double calculateTotalServiceCost(List<Szerviz> services) {
    if (services.isEmpty) return 0;
    return services
        .where((s) => !_isFuel(s) && !s.description.startsWith('Emlékeztető alap: '))
        .fold(0.0, (sum, s) => sum + s.cost);
  }

  double calculateTotalFuelCost(List<Szerviz> services) {
    if (services.isEmpty) return 0;
    return services
        .where((s) => _isFuel(s))
        .fold(0.0, (sum, s) => sum + s.cost);
  }

  double calculateTotalCost(List<Szerviz> services) {
    if (services.isEmpty) return 0;
    return services
        .where((s) => !s.description.startsWith('Emlékeztető alap: '))
        .fold(0.0, (sum, s) => sum + s.cost);
  }

  Map<String, double> getCostDistribution(List<Szerviz> services) {
    final total = calculateTotalCost(services);
    if (total == 0) return {'fuel': 0, 'service': 0, 'fixed': 0};

    final fuel = calculateTotalFuelCost(services);
    final fixed = getFixedCostsBreakdown(services).values.fold(0.0, (a, b) => a + b);
    final service = total - fuel - fixed;

    return {
      'fuel': fuel / total,
      'service': service / total,
      'fixed': fixed / total,
    };
  }

  MonthlyStats calculateMonthlyStats(List<Szerviz> allServices, DateTime selectedMonth) {
    allServices.sort((a, b) => a.date.compareTo(b.date));

    double monthlyCost = 0;
    double monthlyLiters = 0;
    int monthlyDistance = 0;
    double avgConsumption = 0;

    final monthlyServices = allServices.where((s) => s.date.year == selectedMonth.year && s.date.month == selectedMonth.month).toList();
    final fuelingEventsInMonth = monthlyServices.where((s) => _isFuel(s)).toList();

    for (final service in fuelingEventsInMonth) {
      monthlyCost += service.cost;
      monthlyLiters += _extractLiters(service.description);
    }

    if (fuelingEventsInMonth.length >= 2) {
      monthlyDistance = fuelingEventsInMonth.last.mileage - fuelingEventsInMonth.first.mileage;
    }

    final fullTankEvents = allServices
        .where((s) => _isFuel(s) && s.description.toLowerCase().contains('tele'))
        .toList();

    if (fullTankEvents.length >= 2) {
      double totalLitersForConsumption = 0;
      int totalDistanceForConsumption = 0;

      for (int i = 0; i < fullTankEvents.length - 1; i++) {
        final startTank = fullTankEvents[i];
        final endTank = fullTankEvents[i+1];

        if (endTank.date.year == selectedMonth.year && endTank.date.month == selectedMonth.month) {
          final distance = endTank.mileage - startTank.mileage;
          if (distance <= 0) continue;

          double litersInPeriod = 0;
          final startIndexInAll = allServices.indexOf(startTank);
          final endIndexInAll = allServices.indexOf(endTank);

          for (int j = startIndexInAll + 1; j <= endIndexInAll; j++) {
            final s = allServices[j];
            if (_isFuel(s)) {
              litersInPeriod += _extractLiters(s.description);
            }
          }

          totalLitersForConsumption += litersInPeriod;
          totalDistanceForConsumption += distance;
        }
      }

      if(totalDistanceForConsumption > 0 && totalLitersForConsumption > 0) {
        avgConsumption = (totalLitersForConsumption / totalDistanceForConsumption) * 100;
      }
    }

    final double avgPrice = monthlyLiters > 0 ? monthlyCost / monthlyLiters : 0;
    final double avgCostPerKm = monthlyDistance > 0 && avgPrice > 0 && monthlyLiters > 0 ? (monthlyLiters * avgPrice) / monthlyDistance : 0;

    return MonthlyStats(
      totalCost: monthlyCost,
      totalLiters: monthlyLiters,
      totalDistance: monthlyDistance,
      avgConsumption: avgConsumption,
      avgCostPerKm: avgCostPerKm,
      avgPrice: avgPrice,
    );
  }

  List<Szerviz> getTopExpenses(List<Szerviz> services) {
    final sorted = services.where((s) => !_isFuel(s) && !s.description.startsWith('Emlékeztető alap: ')).toList();
    sorted.sort((a, b) => b.cost.compareTo(a.cost));
    return sorted.take(5).toList();
  }

  Map<String, double> getYearlyComparison(List<Szerviz> services) {
    final now = DateTime.now();
    double thisYear = 0;
    double lastYear = 0;

    final maintenanceServices = services.where((s) => !_isFuel(s) && !s.description.startsWith('Emlékeztető alap: ')).toList();

    for (var s in maintenanceServices) {
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

  Map<String, dynamic> getServiceStats(List<Szerviz> services) {
    final realServices = services.where((s) =>
    !_isFuel(s) &&
        !s.description.toLowerCase().startsWith('emlékeztető alap')
    ).toList();

    realServices.sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    final countLastYear = realServices.where((s) => s.date.isAfter(oneYearAgo)).length;

    int avgKmInterval = 0;
    if (realServices.length >= 2) {
      int totalInterval = 0;
      int intervalsCount = 0;
      for (int i = 1; i < realServices.length; i++) {
        final diff = realServices[i].mileage - realServices[i-1].mileage;
        if (diff > 0) {
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
    if (services.isEmpty) return 0;
    
    final realServices = services
        .where((s) => !s.description.startsWith('Emlékeztető alap: '))
        .toList();
        
    if (realServices.length < 2) return 0;
    
    realServices.sort((a, b) => b.date.compareTo(a.date));

    final recentOnes = realServices.take(5).toList();
    
    final last = recentOnes.first;  
    final first = recentOnes.last;  
    
    final days = last.date.difference(first.date).inDays;
    final kmDiff = last.mileage - first.mileage;

    if (days <= 0 || kmDiff <= 0) return 0;
    
    return kmDiff / days;
  }

  Map<String, dynamic> predictNextService(List<Szerviz> services) {
    final dailyKm = getAverageDailyKm(services);
    if (dailyKm <= 0) return {};

    try {
      final reminders = services.where((s) => s.description.startsWith('Emlékeztető alap: ')).toList();
      if (reminders.isEmpty) return {};

      final lastOil = reminders.firstWhere((s) => s.description.contains('Olajcsere'));
      final currentMileage = services.map((s) => s.mileage).reduce(max);
      
      final kmSince = currentMileage - lastOil.mileage;
      final kmLeft = 15000 - kmSince; 

      if (kmLeft < 0) return {'type': 'Olajcsere', 'urgent': true};

      final daysLeft = kmLeft / dailyKm;
      final predictedDate = DateTime.now().add(Duration(days: daysLeft.toInt()));

      return {
        'type': 'Olajcsere',
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
      final relevant = services.where((s) => s.description.toLowerCase().contains(type.toLowerCase()) && !s.description.startsWith('Emlékeztető alap: ')).toList();
      if (relevant.isEmpty) return null;
      
      relevant.sort((a, b) => b.date.compareTo(a.date));
      final lastEvent = relevant.first;
      
      final int validityDays = type.toLowerCase().contains('műszaki') ? 730 : 365;
      final deadline = lastEvent.date.add(Duration(days: validityDays));
      return deadline.difference(DateTime.now()).inDays;
    } catch (e) {
      return null;
    }
  }

  Szerviz? findLastServiceByDescription(List<Szerviz> services, String description) {
    try {
      final filtered = services.where((s) => s.description.toLowerCase().contains(description.toLowerCase()) && !s.description.startsWith('Emlékeztető alap: ')).toList();
      filtered.sort((a, b) => b.date.compareTo(a.date));
      return filtered.isEmpty ? null : filtered.first;
    } catch (e) {
      return null;
    }
  }
}
