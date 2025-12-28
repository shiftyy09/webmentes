// lib/ui/dialogs/fueling_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';

class FuelingDialog extends StatefulWidget {
  final int? lastOdometer;

  const FuelingDialog({super.key, this.lastOdometer});

  @override
  State<FuelingDialog> createState() => _FuelingDialogState();
}

class _FuelingDialogState extends State<FuelingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _litersController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _odometerController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isFullTank = true;
  double? _calculatedConsumption;

  @override
  void initState() {
    super.initState();
    _litersController.addListener(_recalculate);
    _priceController.addListener(_recalculate);
    _odometerController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _litersController.dispose();
    _priceController.dispose();
    _totalCostController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final liters = double.tryParse(_litersController.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    
    if (liters > 0 && price > 0) {
      final total = liters * price;
      _totalCostController.text = total.toStringAsFixed(0);
    }

    final currentOdometer = int.tryParse(_odometerController.text) ?? 0;
    if (_isFullTank && widget.lastOdometer != null && currentOdometer > widget.lastOdometer! && liters > 0) {
      final distance = currentOdometer - widget.lastOdometer!;
      setState(() {
        _calculatedConsumption = (liters / distance) * 100;
      });
    } else {
      setState(() {
        _calculatedConsumption = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() { _selectedDate = pickedDate; });
    }
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final liters = double.tryParse(_litersController.text.replaceAll(',', '.')) ?? 0;
      final cost = double.tryParse(_totalCostController.text) ?? 0;
      final odometer = int.tryParse(_odometerController.text) ?? 0;

      String description = 'Tankolás (${liters.toStringAsFixed(1)} liter)';
      if (_isFullTank) description += ' - Tele';
      if (_calculatedConsumption != null) description += ' - ${_calculatedConsumption!.toStringAsFixed(1)} L/100km';

      final newService = Szerviz(
        description: description,
        date: _selectedDate,
        mileage: odometer,
        cost: cost,
      );
      Navigator.of(context).pop(newService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy. MM. dd.');

    // Egyedi Dialog widget használata az AlertDialog helyett a teljes testreszabhatóságért
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FEJLÉC
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_gas_station, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Tankolás Rögzítése',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // TARTALOM
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildModernField(controller: _litersController, label: 'Mennyiség', suffix: 'Liter', icon: Icons.water_drop, isDecimal: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildModernField(controller: _priceController, label: 'Egységár', suffix: 'Ft/L', icon: Icons.price_change)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildModernField(
                      controller: _totalCostController, 
                      label: 'Fizetendő', 
                      suffix: 'Ft', 
                      icon: Icons.payments, 
                      readOnly: true,
                      highlight: true, // Kiemelt mező
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    _buildModernField(
                      controller: _odometerController, 
                      label: 'Km óra állás', 
                      suffix: 'km', 
                      icon: Icons.speed,
                      helperText: widget.lastOdometer != null ? 'Előző: ${widget.lastOdometer} km' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // DÁTUM ÉS TELE TANK SOR
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Text(dateFormat.format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: _isFullTank ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isFullTank ? Colors.green : Colors.grey.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Text('Tele tank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Switch(
                                value: _isFullTank,
                                activeColor: Colors.green,
                                onChanged: (val) => setState(() { _isFullTank = val; _recalculate(); }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_calculatedConsumption != null)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.orange.shade50]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          children: [
                            const Text('Számított fogyasztás', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '${_calculatedConsumption!.toStringAsFixed(1)} L/100km',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // LÁBLÉC GOMBOKKAL
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Mégse'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('MENTÉS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    bool isDecimal = false,
    bool readOnly = false,
    bool highlight = false,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: TextStyle(
        fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
        fontSize: highlight ? 18 : 16,
        color: highlight ? Colors.green[800] : null,
      ),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, color: highlight ? Colors.green : Colors.grey),
        suffixText: suffix,
        filled: true,
        fillColor: readOnly ? (highlight ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05)) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(isDecimal ? r'[0-9.,]' : r'[0-9]'))],
      validator: (value) => (!readOnly && (value?.isEmpty ?? true)) ? 'Kötelező' : null,
    );
  }
}
