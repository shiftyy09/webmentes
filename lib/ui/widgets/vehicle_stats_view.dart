// lib/ui/widgets/vehicle_stats_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';
import 'package:olajfolt_web/providers.dart';
import 'package:olajfolt_web/services/statistics_service.dart';

class VehicleStatsView extends ConsumerStatefulWidget {
  const VehicleStatsView({super.key});

  @override
  ConsumerState<VehicleStatsView> createState() => _VehicleStatsViewState();
}

class _VehicleStatsViewState extends ConsumerState<VehicleStatsView> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeMonth(int amount) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + amount, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(8), color: theme.colorScheme.primary),
              labelColor: theme.brightness == Brightness.light ? Colors.white : Colors.black,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'ÁTTEKINTÉS'),
                Tab(text: 'ÜZEMANYAG'),
                Tab(text: 'PÉNZÜGY'),
                Tab(text: 'ELŐREJELZÉS'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: servicesAsync.when(
            data: (services) => TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, services),
                _buildFuelTab(context, services),
                _buildFinanceTab(context, services),
                _buildPredictionTab(context, services),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Hiba a statisztikák betöltésekor.')),
          ),
        ),
      ],
    );
  }

  // --- 1. ÁTTEKINTÉS FÜL ---
  Widget _buildOverviewTab(BuildContext context, List<Szerviz> services) {
    final statsService = StatisticsService();
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    final dateFormat = DateFormat('yyyy. MM. dd.');

    final lastOilChange = statsService.findLastServiceByDescription(services, 'olajcsere');
    final totalCost = statsService.calculateTotalCost(services);
    final lastInspection = statsService.findLastServiceByDescription(services, 'műszaki vizsga');

    final stats = [
      _StatCard(icon: Icons.oil_barrel, title: 'Utolsó olajcsere', value: lastOilChange != null ? dateFormat.format(lastOilChange.date) : 'Nincs adat', subtitle: lastOilChange != null ? '${numberFormat.format(lastOilChange.mileage)} km' : '', color: Colors.black87),
      _StatCard(icon: Icons.paid, title: 'Összes szervizköltség', value: '${numberFormat.format(totalCost)} Ft', subtitle: '${services.length} bejegyzés alapján', color: Colors.green),
      _StatCard(icon: Icons.verified, title: 'Műszaki érvényes', value: lastInspection != null ? dateFormat.format(DateTime(lastInspection.date.year + 2, lastInspection.date.month, lastInspection.date.day)) : 'Nincs adat', subtitle: 'A legutóbbi vizsga alapján', color: Colors.blue),
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 350, childAspectRatio: 1.8, crossAxisSpacing: 16, mainAxisSpacing: 16),
      padding: const EdgeInsets.all(16),
      itemCount: stats.length,
      itemBuilder: (context, index) => stats[index],
    );
  }

  // --- 2. ÜZEMANYAG FÜL ---
  Widget _buildFuelTab(BuildContext context, List<Szerviz> services) {
    final theme = Theme.of(context);
    final monthFormat = DateFormat('yyyy. MMMM', 'hu_HU');
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    final statsService = StatisticsService();

    final currentStats = statsService.calculateMonthlyStats(services, _selectedMonth);
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    final prevStats = statsService.calculateMonthlyStats(services, prevMonth);

    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final dailyCost = currentStats.totalCost / daysInMonth;
    final dailyKm = currentStats.totalDistance / daysInMonth;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
            Text(monthFormat.format(_selectedMonth).toUpperCase(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
          ],
        ),
        const Divider(),
        Expanded(
          child: (currentStats.totalCost == 0 && currentStats.totalDistance == 0)
              ? const Center(child: Text('A kiválasztott hónapban nincsenek adatok.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildTrendCard(title: 'Összes Költség', value: '${numberFormat.format(currentStats.totalCost)} Ft', prevValue: prevStats.totalCost, currentValue: currentStats.totalCost, inverse: true, icon: Icons.account_balance_wallet, color: Colors.green),
                          _buildTrendCard(title: 'Átlagfogyasztás', value: '${currentStats.avgConsumption.toStringAsFixed(1)} L', prevValue: prevStats.avgConsumption, currentValue: currentStats.avgConsumption, inverse: true, icon: Icons.local_gas_station, color: Colors.orange, unit: '/100km'),
                          _buildTrendCard(title: 'Megtett Táv', value: '${numberFormat.format(currentStats.totalDistance)} km', prevValue: prevStats.totalDistance.toDouble(), currentValue: currentStats.totalDistance.toDouble(), inverse: false, icon: Icons.map, color: Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('RÉSZLETES ELEMZÉS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              _StatRow(icon: Icons.water_drop, label: 'Összes tankolt mennyiség', value: '${currentStats.totalLiters.toStringAsFixed(1)} liter', color: Colors.teal),
                              const Divider(),
                              _StatRow(icon: Icons.price_change, label: 'Átlagos üzemanyagár', value: '${numberFormat.format(currentStats.avgPrice)} Ft/L', color: Colors.amber[800]!),
                              const Divider(),
                              _StatRow(icon: Icons.calendar_today, label: 'Napi átlagos költség', value: '${numberFormat.format(dailyCost.toInt())} Ft / nap', color: Colors.redAccent),
                              const Divider(),
                              _StatRow(icon: Icons.speed, label: 'Napi átlagos futás', value: '${dailyKm.toStringAsFixed(1)} km / nap', color: Colors.indigo),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // --- 3. PÉNZÜGY FÜL ---
  Widget _buildFinanceTab(BuildContext context, List<Szerviz> services) {
    final statsService = StatisticsService();
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    
    final yearlyComparison = statsService.getYearlyComparison(services);
    final topExpenses = statsService.getTopExpenses(services);
    final fixedCosts = statsService.getFixedCostsBreakdown(services);
    
    // ÚJ: Szerviz statisztikák
    final serviceStats = statsService.getServiceStats(services);
    final serviceCountLastYear = serviceStats['countLastYear'] as int;
    final avgKmInterval = serviceStats['avgKmInterval'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendCard(title: 'Idei Kiadások', value: '${numberFormat.format(yearlyComparison['thisYear'])} Ft', prevValue: yearlyComparison['lastYear']!, currentValue: yearlyComparison['thisYear']!, inverse: true, icon: Icons.calendar_today, color: Colors.blueGrey, unit: ' vs Tavaly (${numberFormat.format(yearlyComparison['lastYear'])})'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Szervizlátogatások (elmúlt 1 év)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('$serviceCountLastYear alkalom', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                        // Ha van elég adat az átlaghoz, megjelenítjük
                        if (avgKmInterval > 0)
                          Text('Átlagosan ${numberFormat.format(avgKmInterval)} km-enként', style: const TextStyle(fontSize: 12, color: Colors.grey))
                        else
                          const Text('Kevés adat az átlaghoz', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Fix Költségek (Idén)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('${numberFormat.format(fixedCosts.values.fold(0.0, (a,b)=>a+b))} Ft', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const Text('Biztosítás, Adó, Műszaki', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('TOP 5 LEGDRÁGÁBB TÉTEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: topExpenses.map((s) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.attach_money)),
                title: Text(s.description, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('yyyy. MM. dd.').format(s.date)),
                trailing: Text('${numberFormat.format(s.cost)} Ft', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }

  // --- 4. ELŐREJELZÉS FÜL ---
  Widget _buildPredictionTab(BuildContext context, List<Szerviz> services) {
    final statsService = StatisticsService();
    final oilPrediction = statsService.predictOilChange(services);
    final daysUntilInspection = statsService.getDaysUntilDeadline(services, 'műszaki');
    final daysUntilInsurance = statsService.getDaysUntilDeadline(services, 'biztosítás');
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HATÁRIDŐK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDeadlineCard('Műszaki Vizsga', daysUntilInspection, Icons.verified)),
              const SizedBox(width: 16),
              Expanded(child: _buildDeadlineCard('Kötelező Biztosítás', daysUntilInsurance, Icons.security)),
            ],
          ),
          const SizedBox(height: 32),
          const Text('OKOS PREDIKCIÓ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 16),
          if (oilPrediction.isNotEmpty)
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.orange.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    const Icon(Icons.oil_barrel, size: 48, color: Colors.orange),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Várható Olajcsere', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                        const SizedBox(height: 8),
                        Text(DateFormat('yyyy. MMMM dd.').format(oilPrediction['date']), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                        Text('Még kb. ${oilPrediction['daysLeft']} nap (${numberFormat.format(oilPrediction['kmLeft'])} km)', style: const TextStyle(color: Colors.grey)),
                      ],
                    )
                  ],
                ),
              ),
            )
          else
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Nincs elég adat az olajcsere becsléséhez.'))),
        ],
      ),
    );
  }

  // --- WIDGET HELPEREK ---

  Widget _buildTrendCard({required String title, required String value, required double prevValue, required double currentValue, required bool inverse, required IconData icon, required Color color, String unit = ''}) {
    double diff = currentValue - prevValue;
    bool isBetter = inverse ? diff < 0 : diff > 0;
    bool isSame = diff == 0 || prevValue == 0;
    String diffText = prevValue > 0 ? '${((diff / prevValue) * 100).abs().toStringAsFixed(1)}%' : 'N/A';

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 12), Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.8))]),
          const SizedBox(height: 8),
          if (!isSame) Row(children: [Icon(diff > 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: isBetter ? Colors.green : Colors.red), const SizedBox(width: 4), Text(diffText, style: TextStyle(color: isBetter ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), const Text(' vs múlt év/hó', style: TextStyle(color: Colors.grey, fontSize: 12))]) else const Text('Nincs változás', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDeadlineCard(String title, int? daysLeft, IconData icon) {
    Color color = Colors.green;
    String text = 'Nincs adat';
    if (daysLeft != null) {
      if (daysLeft < 30) color = Colors.red; else if (daysLeft < 90) color = Colors.orange;
      text = '$daysLeft nap';
    }
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

// --- Top-Level Segédosztályok ---

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({required this.icon, required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            ],
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
