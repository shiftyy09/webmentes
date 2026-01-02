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
  final _yearController = TextEditingController();
  final _kwController = TextEditingController();
  final _cm3Controller = TextEditingController();
  
  int? _eredetvizsga;
  int? _illetek;
  final int _forgalmi = 6000;
  final int _torzskonyv = 6000;
  int? _total;

  void _calculate() {
    final year = int.tryParse(_yearController.text);
    final kw = int.tryParse(_kwController.text);
    final cm3 = int.tryParse(_cm3Controller.text);

    if (year == null || kw == null || cm3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek tölts ki minden mezőt helyesen!')),
      );
      return;
    }

    // Eredetvizsga
    int eredetAr = 0;
    if (cm3 <= 1400) {
      eredetAr = 17000;
    } else if (cm3 <= 2000) {
      eredetAr = 18500;
    } else {
      eredetAr = 20000;
    }

    // Vagyonszerzési illeték
    final currentYear = DateTime.now().year;
    final age = currentYear - year;
    
    int rate = 0;

    if (age <= 3) {
      if (kw <= 40) rate = 345;
      else if (kw <= 80) rate = 450;
      else if (kw <= 120) rate = 550;
      else rate = 850;
    } else if (age <= 8) {
      if (kw <= 40) rate = 300;
      else if (kw <= 80) rate = 395;
      else if (kw <= 120) rate = 450;
      else rate = 650;
    } else if (age <= 12) {
       if (kw <= 40) rate = 230;
      else if (kw <= 80) rate = 300;
      else if (kw <= 120) rate = 300;
      else rate = 460;
    } else {
      if (kw <= 40) rate = 185;
      else if (kw <= 80) rate = 230;
      else if (kw <= 120) rate = 230;
      else rate = 345;
    }

    final illetekAr = kw * rate;

    setState(() {
      _eredetvizsga = eredetAr;
      _illetek = illetekAr;
      _total = eredetAr + illetekAr + _forgalmi + _torzskonyv;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberFormat = NumberFormat.decimalPattern('hu_HU');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Átírási Költség Kalkulátor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // INPUT KÁRTYA
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Jármű Adatai',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(controller: _yearController, label: 'Gyártási év', icon: Icons.calendar_today, suffix: 'év'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(controller: _kwController, label: 'Teljesítmény', icon: Icons.bolt, suffix: 'kW')),
                            const SizedBox(width: 16),
                            // JAVÍTVA: Icons.settings használata Icons.engine helyett
                            Expanded(child: _buildInputField(controller: _cm3Controller, label: 'Lökettérfogat', icon: Icons.settings, suffix: 'cm³')),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _calculate,
                            icon: const Icon(Icons.calculate),
                            label: const Text('SZÁMOLÁS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // EREDMÉNY KÁRTYA
                if (_total != null)
                  Card(
                    color: const Color(0xFF1E1E1E), // Sötét kártya az eredménynek
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Text('Összesen fizetendő', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            '${numberFormat.format(_total)} Ft',
                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const Divider(color: Colors.white24, height: 40),
                          _buildResultRow('Eredetvizsga', _eredetvizsga!),
                          _buildResultRow('Vagyonszerzési illeték', _illetek!),
                          _buildResultRow('Új forgalmi engedély', _forgalmi),
                          _buildResultRow('Törzskönyv', _torzskonyv),
                          const Divider(color: Colors.white24, height: 40),
                          const Text('Eloszlás helyileg:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildResultRow('Eredetvizsgánál fizetendő', _eredetvizsga!, color: Colors.orangeAccent),
                          _buildResultRow('Kormányablakban fizetendő', _illetek! + _forgalmi + _torzskonyv, color: Colors.blueAccent),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixText: suffix,
        filled: true,
        // fillColor: Colors.white, // Opcionális, ha a háttér nem fehér
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
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
          Text(
            '${numberFormat.format(value)} Ft',
            style: TextStyle(color: color ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
