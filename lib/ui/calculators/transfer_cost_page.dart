// lib/ui/calculators/transfer_cost_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TransferCostCalculatorPage extends StatefulWidget {
  const TransferCostCalculatorPage({super.key});

  @override
  State<TransferCostCalculatorPage> createState() => _TransferCostCalculatorPageState();
}

class _TransferCostCalculatorPageState extends State<TransferCostCalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _yearController = TextEditingController();
  final _powerController = TextEditingController();
  final _cm3Controller = TextEditingController();

  final String _jarmuTipusa = 'szemelygepkocsi'; // Fixen csak személygépkocsi
  String _szerzesMod = 'adasvetel';
  bool _eredetvizsgaSzukseges = true;
  bool _isKw = true;

  int? _eredetvizsga;
  int? _illetek;
  final int _forgalmi = 6000;
  final int _torzskonyv = 6000;
  int? _total;

  @override
  void dispose() {
    _yearController.dispose();
    _powerController.dispose();
    _cm3Controller.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek tölts ki minden kötelező mezőt!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final year = int.parse(_yearController.text);
    final power = int.tryParse(_powerController.text) ?? 0;
    final cm3 = int.tryParse(_cm3Controller.text) ?? 0;
    final isDoubled = _szerzesMod != 'adasvetel';

    // 1. EREDETIVIZSGA (a leírásod alapján)
    int eredetvizsgaDij = 0;
    if (_eredetvizsgaSzukseges) {
        if (cm3 <= 1400) eredetvizsgaDij = 22950;
        else if (cm3 <= 2000) eredetvizsgaDij = 24975;
        else eredetvizsgaDij = 27000;
    }
    
    // 2. VAGYONSZERZÉSI ILLETÉK (a leírásod alapján)
    final int kw = _isKw ? power : (power / 1.36).round();
    final currentYear = DateTime.now().year;
    final age = currentYear - year;
    int illetekAlap = 0;

    int rate = 0;
    if (age <= 3) {
      if (kw <= 40) rate = 550; else if (kw <= 80) rate = 650; else if (kw <= 120) rate = 750; else rate = 850;
    } else if (age >= 4 && age <= 8) {
      if (kw <= 40) rate = 450; else if (kw <= 80) rate = 550; else if (kw <= 120) rate = 650; else rate = 750;
    } else { // 8 év felett
      if (kw <= 40) rate = 300; else if (kw <= 80) rate = 450; else if (kw <= 120) rate = 550; else rate = 650;
    }
    illetekAlap = kw * rate;
    
    final illetekAr = isDoubled ? illetekAlap * 2 : illetekAlap;

    setState(() {
      _eredetvizsga = eredetvizsgaDij;
      _illetek = illetekAr;
      _total = eredetvizsgaDij + illetekAr + _forgalmi + _torzskonyv;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    return Scaffold(
      appBar: AppBar(), // CÍM ELTÁVOLÍTVA
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // JAVÍTVA: Chip helyett teljes szélességű Container
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_car, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                const Text('Személygépkocsi Átírás Kalkulátor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildInputField(controller: _yearController, label: 'Gyártási év', icon: Icons.calendar_today, isRequired: true),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildInputField(controller: _powerController, label: 'Teljesítmény', icon: Icons.bolt, suffix: _isKw ? 'kW' : 'LE', isRequired: true)),
                              const SizedBox(width: 8),
                              Padding(padding: const EdgeInsets.only(top: 8.0), child: ToggleButtons(isSelected: [_isKw, !_isKw], onPressed: (i) => setState(() => _isKw = i == 0), borderRadius: BorderRadius.circular(8), children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('kW')), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('LE'))])),
                            ],
                          ),
                           const SizedBox(height: 16),
                          _buildInputField(controller: _cm3Controller, label: 'Lökettérfogat', icon: Icons.settings, suffix: 'cm³', isRequired: true),
                          const SizedBox(height: 16),
                           _buildDropdownField('Szerzés módja', _szerzesMod, {'adasvetel': 'Adásvétel', 'orokles': 'Öröklés', 'ajandekazas': 'Ajándékozás'}, (v) => setState(()=> _szerzesMod=v!)),
                           const Text('Öröklés és ajándékozás esetén az illeték dupla!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                           const SizedBox(height: 16),
                          CheckboxListTile(
                            title: const Text('Eredetvizsgálat szükséges'),
                            value: _eredetvizsgaSzukseges,
                            onChanged: (val) => setState(() => _eredetvizsgaSzukseges = val!),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _calculate,
                              icon: const Icon(Icons.calculate),
                              label: const Text('SZÁMOLÁS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE69500), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_total != null) _buildResultsCard(numberFormat, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(NumberFormat numberFormat, ThemeData theme) {
    return Card(
      color: const Color(0xFF1E1E1E), elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Összesen fizetendő', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('${numberFormat.format(_total)} Ft', style: const TextStyle(color: Color(0xFFE69500), fontSize: 36, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 40),
            _buildResultRow('Eredetvizsga', _eredetvizsga ?? 0),
            _buildResultRow('Vagyonszerzési illeték', _illetek ?? 0),
            _buildResultRow('Új forgalmi engedély', _forgalmi),
            _buildResultRow('Törzskönyv', _torzskonyv),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String currentValue, Map<String, String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, String? suffix, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixText: suffix,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) return 'Kötelező mező';
        return null;
      },
    );
  }

  Widget _buildResultRow(String label, int value, {Color? color}) {
    final numberFormat = NumberFormat.decimalPattern('hu_HU');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text('${numberFormat.format(value)} Ft', style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
