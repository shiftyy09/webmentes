import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../modellek/jarmu.dart';
import '../../providers.dart';
import '../../services/firestore_service.dart';
import '../../services/search_service.dart';
import '../widgets/success_overlay.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsedCarValuePage extends ConsumerStatefulWidget {
  final Jarmu vehicle;
  const UsedCarValuePage({super.key, required this.vehicle});

  @override
  ConsumerState<UsedCarValuePage> createState() => _UsedCarValuePageState();
}

class _UsedCarValuePageState extends ConsumerState<UsedCarValuePage> with TickerProviderStateMixin {
  String _category = 'Középkategória';
  String _equipment = 'Közepes';
  String _fuelType = 'Benzin';
  double _condition = 7.0; 
  
  bool _isAnalyzing = false;
  String _analysisStatus = '';
  Map<String, dynamic>? _result;
  String? _quotaError;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _categories = ['Városi kisautó', 'Középkategória', 'SUV / Crossover', 'Prémium / Luxus', 'Haszonjármű', 'Sportautó'];
  final List<String> _equipments = ['Alap (Fapad)', 'Közepes', 'Magas (Full extra)'];
  final List<String> _fuelTypes = ['Benzin', 'Dízel', 'Hibrid', 'Elektromos', 'LPG'];
  final List<String> _transmissions = ['Manuális', 'Automata'];
  String _transmission = 'Manuális';
  final TextEditingController _engineSizeController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  String _powerUnit = 'LE';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    if (widget.vehicle.extraData != null) {
      _category = widget.vehicle.extraData!['category'] ?? 'Középkategória';
      _equipment = widget.vehicle.extraData!['equipment'] ?? 'Közepes';
      _fuelType = widget.vehicle.extraData!['fuelType'] ?? 'Benzin';
      _transmission = widget.vehicle.extraData!['transmission'] ?? 'Manuális';
      _condition = (widget.vehicle.extraData!['condition'] ?? 7.0).toDouble();
      _engineSizeController.text = widget.vehicle.extraData!['engineSize']?.toString() ?? '';
      _powerController.text = widget.vehicle.extraData!['power']?.toString() ?? '';
      _powerUnit = widget.vehicle.extraData!['powerUnit'] ?? 'LE';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _engineSizeController.dispose();
    _powerController.dispose();
    super.dispose();
  }

  Future<bool> _checkAndIncrementQuota(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final snapshot = await userDoc.get();
    final data = snapshot.data();
    if (data?['isPremium'] ?? false) return true;
    final now = DateTime.now();
    final String monthKey = '${now.year}-${now.month}';
    final Map<String, dynamic> aiUsage = data?['aiUsage'] ?? {};
    int count = aiUsage[monthKey] ?? 0;
    if (count >= 1) return false;
    await userDoc.set({'aiUsage': { monthKey: count + 1 }}, SetOptions(merge: true));
    return true;
  }

  void _runSmartAIAnalysis(int serviceCount) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    if (_engineSizeController.text.isEmpty || _powerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kérlek töltsd ki a motoradatokat a pontos becsléshez!'), backgroundColor: Color(0xFFE69500)));
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
      _quotaError = null;
    });

    final now = DateTime.now();
    final String monthKey = '${now.year}-${now.month}';
    final String cacheKey = '${_fuelType}_${_engineSizeController.text}_${_transmission}';
    final String lastCacheKey = widget.vehicle.extraData?['lastCacheKey'] ?? '';
    final String lastSyncMonth = widget.vehicle.extraData?['lastSyncMonth'] ?? '';
    double? marketBasePrice = (widget.vehicle.extraData?['lastMarketPrice'] as num?)?.toDouble();

    bool wasFallbackUsed = false;
    String source = 'Valós piaci hirdetések (Cache)';

    if (marketBasePrice == null || lastSyncMonth != monthKey || lastCacheKey != cacheKey) {
      final hasQuota = await _checkAndIncrementQuota(user.uid);
      if (!hasQuota) {
        setState(() {
          _quotaError = 'Elérted a havi 1 ingyenes AI keresési limitedet. Fizess elő a korlátlan hozzáférésért!';
          _isAnalyzing = false;
        });
        _runFallbackAnalysis(serviceCount, user.uid);
        return;
      }

      setState(() => _analysisStatus = 'Neural Engine inicializálása...');
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() => _analysisStatus = 'Piaci hirdetések szkennelése...');
      
      final searchService = CarSearchService();
      marketBasePrice = await searchService.fetchMarketMedianPrice(
        make: widget.vehicle.make, 
        model: widget.vehicle.model, 
        year: widget.vehicle.year,
        fuelType: _fuelType,
        engineSize: _engineSizeController.text,
        power: '${_powerController.text} $_powerUnit',
        transmission: _transmission,
      );

      if (marketBasePrice == null) {
        wasFallbackUsed = true;
        source = 'Algoritmikus becslés (Fallback)';
        double baseNewPrice = 10000000;
        if (_category == 'Városi kisautó') baseNewPrice = 6000000;
        else if (_category == 'Középkategória') baseNewPrice = 11000000;
        else if (_category == 'SUV / Crossover') baseNewPrice = 14000000;
        else if (_category == 'Prémium / Luxus') baseNewPrice = 25000000;
        int age = DateTime.now().year - widget.vehicle.year;
        marketBasePrice = baseNewPrice * pow(0.87, max(0, age)).toDouble();
      } else {
        source = 'Valós piaci hirdetések';
        final updatedVehicle = widget.vehicle.copyWith(
          extraData: {
            ...widget.vehicle.extraData ?? {},
            'lastMarketPrice': marketBasePrice,
            'lastSyncMonth': monthKey,
            'lastCacheKey': cacheKey,
          }
        );
        await ref.read(firestoreServiceProvider).upsertVehicle(user.uid, updatedVehicle);
      }
    }

    final steps = ['Szerviztörténet validálása...', 'Amortizációs görbe illesztése...', 'Végleges kiértékelés...'];
    for (var step in steps) {
      if (!mounted) return;
      setState(() => _analysisStatus = step);
      await Future.delayed(const Duration(milliseconds: 700));
    }

    _calculateFinalResult(marketBasePrice!, serviceCount, wasFallbackUsed, source, user.uid);
  }

  void _runFallbackAnalysis(int serviceCount, String userId) async {
    double baseNewPrice = 10000000;
    if (_category == 'Városi kisautó') baseNewPrice = 6000000;
    else if (_category == 'Középkategória') baseNewPrice = 11000000;
    else if (_category == 'SUV / Crossover') baseNewPrice = 14000000;
    int age = DateTime.now().year - widget.vehicle.year;
    double marketBasePrice = baseNewPrice * pow(0.87, max(0, age)).toDouble();
    _calculateFinalResult(marketBasePrice, serviceCount, true, 'Algoritmikus modell (Limit)', userId);
  }

  void _calculateFinalResult(double marketBasePrice, int serviceCount, bool wasFallbackUsed, String source, String userId) async {
    int age = DateTime.now().year - widget.vehicle.year;
    double expectedKm = age * 15000.0;
    double kmDifference = widget.vehicle.mileage - expectedKm;
    double kmImpact = 1.0 - (kmDifference / 600000);
    double equipmentMultiplier = _equipment == 'Alap (Fapad)' ? 0.92 : (_equipment == 'Magas (Full extra)' ? 1.12 : 1.0);
    double maintenanceBonus = 1.0 + (min(serviceCount, 20) * 0.01); 
    double conditionMultiplier = 0.8 + (_condition / 10) * 0.3;
    double predictedValue = marketBasePrice * kmImpact * equipmentMultiplier * maintenanceBonus * conditionMultiplier;

    setState(() {
      _isAnalyzing = false;
      _result = {
        'value': predictedValue,
        'maintenanceImpact': (maintenanceBonus - 1.0) * 100,
        'conditionImpact': (conditionMultiplier - 1.0) * 100,
        'lowRange': predictedValue * 0.94,
        'highRange': predictedValue * 1.06,
        'confidence': wasFallbackUsed ? 60 : min(75 + (serviceCount * 2), 98),
        'source': source,
      };
    });

    final updatedVehicle = widget.vehicle.copyWith(extraData: {...widget.vehicle.extraData ?? {}, 'category': _category, 'equipment': _equipment, 'fuelType': _fuelType, 'transmission': _transmission, 'engineSize': _engineSizeController.text, 'power': _powerController.text, 'powerUnit': _powerUnit, 'condition': _condition, 'lastPredictedValue': predictedValue.toInt()});
    await ref.read(firestoreServiceProvider).upsertVehicle(userId, updatedVehicle);
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesForSelectedVehicleProvider);
    final nf = NumberFormat.decimalPattern('hu_HU');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('AI Értékbecslő', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFE69500)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [const Color(0xFFE69500).withOpacity(0.05), const Color(0xFF121212)],
          ),
        ),
        child: servicesAsync.when(
          data: (services) {
            final realServicesCount = services.where((s) => !s.description.startsWith('Emlékeztető alap: ')).length;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    children: [
                      _buildHeader(),
                      if (_quotaError != null) _buildQuotaWarning(),
                      const SizedBox(height: 40),
                      if (_result == null && !_isAnalyzing) ...[
                        _buildForm(),
                        const SizedBox(height: 40),
                        _buildActionButton(realServicesCount),
                      ] else if (_isAnalyzing) ...[
                        _buildAIProcessingView(),
                      ] else ...[
                        _buildResultView(nf),
                      ],
                      const SizedBox(height: 60),
                      _buildDisclaimer(),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE69500))),
          error: (e, st) => const Center(child: Text('Hiba történt')),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE69500).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFE69500), size: 32),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.vehicle.make} ${widget.vehicle.model}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${widget.vehicle.year} • ${widget.vehicle.licensePlate}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildCard(
          title: 'TECHNIKAI PARAMÉTEREK',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildDropdown('Üzemanyag', _fuelType, _fuelTypes, (v) => setState(() => _fuelType = v!))),
                  const SizedBox(width: 20),
                  Expanded(child: _buildInput('Hengerűrtartalom', _engineSizeController, 'cm³')),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _buildDropdown('Váltó', _transmission, _transmissions, (v) => setState(() => _transmission = v!))),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teljesítmény', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: _powerController, style: const TextStyle(color: Colors.white), decoration: _inputDeco(''))),
                            const SizedBox(width: 10),
                            ToggleButtons(
                              isSelected: [_powerUnit == 'LE', _powerUnit == 'kW'],
                              onPressed: (i) => setState(() => _powerUnit = i == 0 ? 'LE' : 'kW'),
                              color: Colors.white38,
                              selectedColor: Colors.black,
                              fillColor: const Color(0xFFE69500),
                              borderRadius: BorderRadius.circular(12),
                              constraints: const BoxConstraints(minHeight: 45, minWidth: 45),
                              children: const [Text('LE'), Text('kW')],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildCard(
          title: 'ÁLLAPOT ÉS BESOROLÁS',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildDropdown('Kategória', _category, _categories, (v) => setState(() => _category = v!))),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDropdown('Felszereltség', _equipment, _equipments, (v) => setState(() => _equipment = v!))),
                ],
              ),
              const SizedBox(height: 32),
              const Align(alignment: Alignment.centerLeft, child: Text('Általános állapot', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              Slider(
                value: _condition, min: 1, max: 10, divisions: 9,
                activeColor: const Color(0xFFE69500),
                inactiveColor: Colors.white10,
                onChanged: (v) => setState(() => _condition = v),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Leharcolt', style: TextStyle(color: Colors.white38, fontSize: 11)), Text('Átlagos', style: TextStyle(color: Colors.white38, fontSize: 11)), Text('Újszerű', style: TextStyle(color: Colors.white38, fontSize: 11))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFE69500), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: _inputDeco(suffix)),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged, dropdownColor: const Color(0xFF2A2A2A), decoration: _inputDeco(''),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String suffix) => InputDecoration(
    suffixText: suffix, suffixStyle: const TextStyle(color: Colors.white38),
    filled: true, fillColor: Colors.white.withOpacity(0.03),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );

  Widget _buildAIProcessingView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(color: Color(0xFFE69500), strokeWidth: 8)),
          const SizedBox(height: 40),
          Text(_analysisStatus, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          const Text('A legfrissebb piaci adatok és a szervizmúlt szinkronizálása...', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildResultView(NumberFormat nf) {
    final val = _result!['value'] as double;
    return Column(
      children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFE69500), Color(0xFFB37700)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: const Color(0xFFE69500).withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))],
          ),
          child: Column(
            children: [
              const Text('PIACI ÉRTÉK BECSLÉS', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12)),
              const SizedBox(height: 20),
              Text('${nf.format(val.toInt())} Ft', style: const TextStyle(color: Colors.black, fontSize: 56, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text('Ajánlott hirdetési ár: ${nf.format(_result!['lowRange'].toInt())} - ${nf.format(_result!['highRange'].toInt())} Ft', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.psychology, size: 20), const SizedBox(width: 10), Text('AI Megbízhatóság: ${_result!['confidence']}%', style: const TextStyle(fontWeight: FontWeight.bold))]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: _buildResultMiniCard('Szerviz múlt bónusz', '+${_result!['maintenanceImpact'].toStringAsFixed(1)}%', Icons.verified_rounded, Colors.greenAccent)),
            const SizedBox(width: 20),
            Expanded(child: _buildResultMiniCard('Állapot korrekció', '${_result!['conditionImpact'] > 0 ? '+' : ''}${_result!['conditionImpact'].toStringAsFixed(1)}%', Icons.auto_graph_rounded, Colors.orangeAccent)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Forrás: ${_result!['source']}', style: const TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildResultMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(int serviceCount) {
    return SizedBox(
      width: double.infinity, height: 70,
      child: ElevatedButton.icon(
        onPressed: () => _runSmartAIAnalysis(serviceCount),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI ELEMZÉS INDÍTÁSA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE69500), foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
      child: Row(children: const [Icon(Icons.info_outline, color: Colors.white24, size: 20), SizedBox(width: 16), Expanded(child: Text('A becslés valós hirdetések és matematikai amortizációs modellek alapján készül. A tényleges ár függ a piaci kereslettől.', style: TextStyle(color: Colors.white24, fontSize: 11)))]),
    );
  }

  Widget _buildQuotaWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 24), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red.withOpacity(0.2))),
      child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent), const SizedBox(width: 16), Expanded(child: Text(_quotaError!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)))]),
    );
  }
}
