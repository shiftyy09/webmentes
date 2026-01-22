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
            height: 45,
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), color: theme.colorScheme.primary, boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'DASHBOARD'),
                Tab(text: 'ÜZEMANYAG'),
                Tab(text: 'PÉNZÜGY'),
                Tab(text: 'PREDIKCIÓ'),
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
                _buildDashboardTab(context, services),
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

  // --- 1. MODERN DASHBOARD FÜL ---
  Widget _buildDashboardTab(BuildContext context, List<Szerviz> services) {
    final statsService = StatisticsService();
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    
    final totalCost = statsService.calculateTotalCost(services);
    final dailyKm = statsService.getAverageDailyKm(services);
    final costDist = statsService.getCostDistribution(services);
    final prediction = statsService.predictNextService(services);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AUTÓ ÁLLAPOT ÉS KÖLTSÉGEK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.1)),
          const SizedBox(height: 20),
          
          // FŐ KÁRTYÁK GRID
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMainCard(
                    constraints.maxWidth,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Összesített Költség',
                    value: '${numberFormat.format(totalCost.toInt())} Ft',
                    subtitle: 'A járművödre fordított teljes összeg',
                    color: Colors.blue.shade700,
                  ),
                  _buildMainCard(
                    constraints.maxWidth,
                    icon: Icons.trending_up_rounded,
                    title: 'Napi Átlag Futás',
                    value: '${dailyKm.toStringAsFixed(1)} km',
                    subtitle: 'Használati intenzitás naponta',
                    color: Colors.orange.shade700,
                  ),
                  _buildMainCard(
                    constraints.maxWidth,
                    icon: Icons.event_note_rounded,
                    title: 'Várható Szerviz',
                    value: prediction.isNotEmpty ? (prediction['urgent'] == true ? 'AZONNAL!' : DateFormat('yyyy. MM. dd.').format(prediction['date'])) : 'Nincs adat',
                    subtitle: prediction.isNotEmpty ? 'Következő: ${prediction['type']}' : 'Kevés adat a jósláshoz',
                    color: prediction['urgent'] == true ? Colors.red : Colors.green.shade700,
                  ),
                ],
              );
            }
          ),

          const SizedBox(height: 32),
          const Text('KÖLTSÉGMEGOSZLÁS (TCO)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildCostDistributionBar(costDist),

          const SizedBox(height: 32),
          const Text('UTOLSÓ ESEMÉNYEK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildRecentActivityList(services),
        ],
      ),
    );
  }

  // --- 2. ÜZEMANYAG FÜL (Frissítve) ---
  Widget _buildFuelTab(BuildContext context, List<Szerviz> services) {
    final theme = Theme.of(context);
    final monthFormat = DateFormat('yyyy. MMMM', 'hu_HU');
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    final statsService = StatisticsService();

    final currentStats = statsService.calculateMonthlyStats(services, _selectedMonth);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => _changeMonth(-1)),
              const SizedBox(width: 20),
              Text(monthFormat.format(_selectedMonth).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(width: 20),
              IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 18), onPressed: () => _changeMonth(1)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: (currentStats.totalCost == 0)
              ? const Center(child: Text('Nincs tankolási adat ebben a hónapban.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.local_gas_station, 'Havi fogyasztás', '${currentStats.avgConsumption.toStringAsFixed(2)} L/100km', Colors.orange),
                      _buildInfoRow(Icons.payments, 'Üzemanyagra költve', '${numberFormat.format(currentStats.totalCost)} Ft', Colors.green),
                      _buildInfoRow(Icons.map, 'Havi futásteljesítmény', '${numberFormat.format(currentStats.totalDistance)} km', Colors.blue),
                      _buildInfoRow(Icons.price_check, 'Átlagos liter ár', '${numberFormat.format(currentStats.avgPrice)} Ft/L', Colors.purple),
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
    final topExpenses = statsService.getTopExpenses(services);
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('LEGDRÁGÁBB SZERVIZEK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        ...topExpenses.map((s) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.warning_amber_rounded, color: Colors.red)),
            title: Text(s.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('yyyy. MM. dd.').format(s.date)),
            trailing: Text('${numberFormat.format(s.cost)} Ft', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.red, fontSize: 16)),
          ),
        )),
      ],
    );
  }

  // --- 4. PREDIKCIÓ FÜL ---
  Widget _buildPredictionTab(BuildContext context, List<Szerviz> services) {
    final statsService = StatisticsService();
    final daysUntilMuzsaki = statsService.getDaysUntilDeadline(services, 'műszaki');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: Colors.amber),
          const SizedBox(height: 24),
          const Text('MESTERSÉGES INTELLIGENCIA ALAPÚ BECSLÉS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 32),
          if (daysUntilMuzsaki != null)
             _buildPredictionCard('Műszaki vizsga lejárata', '$daysUntilMuzsaki nap múlva', daysUntilMuzsaki < 30 ? Colors.red : Colors.green)
          else
            const Text('Nincs elég adat az előrejelzéshez.'),
        ],
      ),
    );
  }

  // --- MODERNEBB WIDGETEK ---

  Widget _buildMainCard(double width, {required IconData icon, required String title, required String value, required String subtitle, required Color color}) {
    final cardWidth = width > 800 ? (width - 64) / 3 : (width - 32);
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCostDistributionBar(Map<String, double> dist) {
    return Column(
      children: [
        Container(
          height: 35,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.withOpacity(0.1)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                if (dist['fuel']! > 0) Expanded(flex: (dist['fuel']! * 100).toInt(), child: Container(color: Colors.orange, child: const Center(child: Icon(Icons.local_gas_station, size: 14, color: Colors.white)))),
                if (dist['service']! > 0) Expanded(flex: (dist['service']! * 100).toInt(), child: Container(color: Colors.blue, child: const Center(child: Icon(Icons.build, size: 14, color: Colors.white)))),
                if (dist['fixed']! > 0) Expanded(flex: (dist['fixed']! * 100).toInt(), child: Container(color: Colors.purple, child: const Center(child: Icon(Icons.security, size: 14, color: Colors.white)))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Üzemanyag', Colors.orange, '${(dist['fuel']! * 100).toStringAsFixed(0)}%'),
            _buildLegendItem('Szerviz', Colors.blue, '${(dist['service']! * 100).toStringAsFixed(0)}%'),
            _buildLegendItem('Fix költség', Colors.purple, '${(dist['fixed']! * 100).toStringAsFixed(0)}%'),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percent) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 4),
        Text(percent, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentActivityList(List<Szerviz> services) {
    final recent = services.where((s) => !s.description.startsWith('Emlékeztető alap: ')).take(3).toList();
    return Column(
      children: recent.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(s.description.contains('tankolás') ? Icons.local_gas_station : Icons.settings, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(child: Text(s.description, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text(DateFormat('MM. dd.').format(s.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
