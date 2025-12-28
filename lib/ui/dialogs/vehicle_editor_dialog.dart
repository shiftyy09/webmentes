// lib/ui/dialogs/vehicle_editor_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:olajfolt_web/alap/konstansok.dart';
import 'package:olajfolt_web/alap/jarmu_adatok.dart';
import 'package:olajfolt_web/modellek/jarmu.dart';
import 'package:olajfolt_web/modellek/karbantartas_bejegyzes.dart';

class VehicleEditorDialog extends StatefulWidget {
  final Jarmu? vehicle;

  const VehicleEditorDialog({super.key, this.vehicle});

  @override
  State<VehicleEditorDialog> createState() => _VehicleEditorDialogState();
}

class _VehicleEditorDialogState extends State<VehicleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _licensePlateController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;
  late final TextEditingController _vinController;
  
  String? _selectedMake;
  String? _selectedVezerlesTipus;

  final Map<String, TextEditingController> _serviceDateControllers = {};
  final Map<String, TextEditingController> _serviceMileageControllers = {};
  // Külön tároló a matrica típusnak
  String? _selectedVignetteType; 
  final List<String> _vignetteTypes = ['Heti (10 napos)', 'Havi', 'Éves (Országos)', 'Éves (Megyei)'];

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _licensePlateController = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
    _selectedMake = widget.vehicle?.make;
    if (_selectedMake != null && !SUPPORTED_CAR_MAKES.contains(_selectedMake)) {
       _selectedMake = null; 
    }
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _yearController = TextEditingController(text: widget.vehicle?.year.toString() ?? '');
    _mileageController = TextEditingController(text: widget.vehicle?.mileage.toString() ?? '');
    _vinController = TextEditingController(text: widget.vehicle?.vin ?? '');
    _selectedVezerlesTipus = widget.vehicle?.vezerlesTipusa;

    for (var serviceType in ALL_REMINDER_SERVICE_TYPES) {
      _serviceDateControllers[serviceType] = TextEditingController();
      _serviceMileageControllers[serviceType] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    _serviceDateControllers.forEach((_, controller) => controller.dispose());
    _serviceMileageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final vehicle = Jarmu(
        id: widget.vehicle?.id,
        licensePlate: _licensePlateController.text.toUpperCase(),
        make: _selectedMake!,
        model: _modelController.text,
        year: int.tryParse(_yearController.text) ?? 0,
        mileage: int.tryParse(_mileageController.text) ?? 0,
        vin: _vinController.text,
        vezerlesTipusa: _selectedVezerlesTipus,
      );

      final List<Szerviz> initialServices = [];
      _serviceDateControllers.forEach((serviceType, dateController) {
        if (dateController.text.isNotEmpty) {
          final mileageController = _serviceMileageControllers[serviceType]!;
          
          String description = '$REMINDER_PREFIX$serviceType';
          // Ha matrica és van kiválasztva típus, hozzáfűzzük
          if (serviceType == 'Pályamatrica' && _selectedVignetteType != null) {
            description += ' ($_selectedVignetteType)';
          }

          initialServices.add(Szerviz(
            description: description,
            date: DateFormat('yyyy.MM.dd').parse(dateController.text),
            mileage: int.tryParse(mileageController.text) ?? 0,
            cost: 0,
          ));
        }
      });
      Navigator.of(context).pop({'vehicle': vehicle, 'services': initialServices});
    }
  }
  
  Future<void> _pickDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      controller.text = DateFormat('yyyy.MM.dd').format(pickedDate);
    }
  }

  String _getDateLabel(String serviceType) {
    if (serviceType.contains('Műszaki')) return 'Utolsó vizsga dátuma';
    if (serviceType.contains('biztosítás') || serviceType.contains('CASCO')) return 'Évforduló dátuma';
    if (serviceType.contains('matrica')) return 'Érvényesség kezdete';
    return 'Utolsó csere dátuma';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vezerlesTipusok = ['Szíj', 'Lánc', 'Nincs'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SizedBox(
        width: 700,
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
                    child: const Icon(Icons.directions_car, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _isEditing ? 'Jármű Szerkesztése' : 'Új Jármű Hozzáadása',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // TARTALOM
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ALAPADATOK
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alapadatok', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildModernField(controller: _licensePlateController, label: 'Rendszám', icon: Icons.badge, isRequired: true)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedMake,
                                    items: SUPPORTED_CAR_MAKES.map((make) => DropdownMenuItem(value: make, child: Text(make))).toList(),
                                    onChanged: (value) => setState(() => _selectedMake = value),
                                    decoration: _buildInputDecoration(label: 'Gyártmány', icon: Icons.factory),
                                    validator: (value) => (value == null) ? 'Kötelező' : null,
                                    menuMaxHeight: 300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildModernField(controller: _modelController, label: 'Modell', icon: Icons.directions_car_filled, isRequired: true)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildModernField(controller: _yearController, label: 'Évjárat', icon: Icons.calendar_today, isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildModernField(controller: _mileageController, label: 'Futásteljesítmény', icon: Icons.speed, suffix: 'km', isNumber: true)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildModernField(controller: _vinController, label: 'Alvázszám (VIN)', icon: Icons.fingerprint, isRequired: false)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedVezerlesTipus,
                              items: vezerlesTipusok.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                              onChanged: (value) => setState(() => _selectedVezerlesTipus = value),
                              decoration: _buildInputDecoration(label: 'Vezérlés típusa', icon: Icons.settings),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // KEZDETI SZERVIZADATOK
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text('Kezdeti szervizadatok (Opcionális)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                            leading: Icon(Icons.build, color: theme.colorScheme.primary),
                            childrenPadding: const EdgeInsets.all(16),
                            children: ALL_REMINDER_SERVICE_TYPES.map((serviceType) {
                              final bool showKm = KM_BASED_SERVICE_TYPES.contains(serviceType);
                              final String dateLabel = _getDateLabel(serviceType);
                              final bool isVignette = serviceType == 'Pályamatrica';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(flex: 2, child: Text(serviceType, style: const TextStyle(fontWeight: FontWeight.w500))),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: _buildModernField(
                                            controller: _serviceDateControllers[serviceType]!,
                                            label: dateLabel,
                                            icon: Icons.calendar_month,
                                            isDate: true,
                                            isRequired: false,
                                            isSmall: true,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: showKm && !isVignette ? _buildModernField(
                                            controller: _serviceMileageControllers[serviceType]!,
                                            label: 'Km állás',
                                            icon: Icons.speed,
                                            isNumber: true,
                                            isRequired: false,
                                            isSmall: true,
                                          ) : const SizedBox(),
                                        ),
                                      ],
                                    ),
                                    // Pályamatrica esetén extra dropdown
                                    if (isVignette)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0, left: 120), // Kis behúzás
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedVignetteType,
                                          items: _vignetteTypes.map((type) => DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (value) => setState(() => _selectedVignetteType = value),
                                          decoration: _buildInputDecoration(label: 'Matrica típusa', icon: Icons.confirmation_number, isSmall: true),
                                          style: const TextStyle(fontSize: 13, color: Colors.black),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
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

  InputDecoration _buildInputDecoration({required String label, required IconData icon, bool isSmall = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey, size: isSmall ? 18 : 24),
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      contentPadding: isSmall ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? suffix,
    bool isNumber = false,
    bool isRequired = true,
    bool isDate = false,
    bool isSmall = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isDate,
      onTap: isDate ? () => _pickDate(controller) : null,
      decoration: _buildInputDecoration(label: label, icon: icon, isSmall: isSmall).copyWith(suffixText: suffix),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      validator: (value) => (isRequired && (value?.isEmpty ?? true)) ? 'Kötelező' : null,
      style: isSmall ? const TextStyle(fontSize: 14) : null,
    );
  }
}
